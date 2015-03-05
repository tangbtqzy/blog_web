# coding: utf-8

# 公共函数库

class SysMailer < ActionMailer::Base

  default :content_type => "text/html"

  #ActionMailer::Base.raise_delivery_errors = true

  def alert(recipients, subject, body, from = '')
    # 注意：尖括号前面一定要包含空格!!!
    @from = (from == '' ? "瑞卡系统 <system@reocar.com>" : from)
    @recipients = recipients
    @subject = subject
    @body = body
  end

end


class Util

  COLOR_GRAY    = 30
  COLOR_RED     = 31
  COLOR_GREEN   = 32
  COLOR_YELLOW  = 33
  COLOR_BLUE    = 34
  COLOR_WHITE   = 37

  class << self

    #判断是否是正式版本 => {:true => 需要执行验证码验证和错误记录等操作 }
    def formal_vision?
      #REOCAR_VERSION == 'com' || REOCAR_VERSION == 'com.001'
      true
    end

    # recipients: seperated by ','
    def send_email(recipients, subject, body, from = '')
      SysMailer.alert(recipients, subject, body, from).deliver
    end

    # 将调试信息打到日志上，可以指定颜色
    def debug(message, color = COLOR_GREEN)
      Rails.logger.debug("\n  \e\[5;#{color};1m#{message}\e\[0m\n\n")
    end

    # 将调试信息打到日志上，可以指定颜色
    def info(message, color = COLOR_GREEN)
      Rails.logger.info("\n  \e\[5;#{color};1m#{message}\e\[0m\n\n")
    end

    # 倾印对象
    def dump(obj)
      if obj.respond_to?(:each)
        obj.each { | item | dump(item) }
      elsif obj.respond_to?(:attributes)
        debug obj.attributes
      else
        debug obj
      end
    end

    # 截断字符串
    def cut(text, length = 20, tail = "...")
      len, text = length, text.gsub(/<\/?[^>]*>|\s+|　/, '')
      (text.reverse!; len /= -1.0; tail = '') if length < 0 # 如果为负数，截取后面
      l, char_array = 0, text.unpack("U*")
      char_array.each_with_index do | c, i |
        l += (c < 127 ? 0.5 : 1)
        (text = (i < char_array.length - 1 ? char_array[0..i].pack("U*") + tail : text); break) if l >= len
      end
      return length < 0 ? text.reverse : text
    end

    # 让对象数组按照某个数组的顺序来排
    def sort_by_array(array, att_sym, index_array)
      return array.sort do |a, b|
        index_array.index(a.send(att_sym)).to_i <=> index_array.index(b.send(att_sym)).to_i
      end
    end

    # 将数字格式化成货币显示形式
    def to_c(v)
      v = v.to_f.round(2)
      parts = v.to_s.to_str.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
      v = parts.join('.')
      v = (v =~ /\.\d$/ ? v + '0' : v)
      v = (v == '0' ? '0.00' : v)
      v
    end

    # 将哈希里所有的数字格式化成货币数字
    def wash_for_currency!(data)
      data.each do | k, v |
        if v.is_a?(Hash)
          wash_for_currency!(v)
        elsif v.is_a?(Numeric) || v =~ /^[\d\.]+$/
          data[k] = CurrencyNumber.new(v.to_s)
        end
      end
    end

    # 清洗参数，把字符串的key转换为symbolize，把时间字符串转换成时间对象，把字符串转换成数字等等！
    def wash(params)
      params = params.deep_dup
      # params.symbolize_keys! if params.is_a?(Hash)
      deep_wash!(params)
      params
    end

    # 智能多表查询（自动JOIN表，拼装条件） 详细介绍请点击：
    # {这里}[link:../开发文档/files/doc/dev/search2_txt.html]
    #   - params: 查询参数，一般来自表单（<FORM>....</FORM>）
    #   - key_model: 关键Model（同时也是结果集的基本元素），例如Order, User, Car, SubOrder等等
    def search2(params, key_model = PgOrder, is_only_build_conditions = false, is_enable_smart_joins = true)

      params = params.with_indifferent_access if params.is_a?(Hash)
      valid_models, all_models, conditions, values = [], [], [], [], []
      specified_assocs, is_debug = {}, params[:debug] || false

      # key_model有可能是ActiveRecord::Relation，我们需要提取原始的Model！
      raw_model = key_model.table_name.classify.constantize unless is_only_build_conditions
      # 组装条件
      params.each do | k, v |
        if /__diy_/ =~ k # DIY的条件，直接原样组装
          conditions << v
        else
          prefix, table_name = k.split(/^table_/)
          next if table_name.blank?
          m = table_name.classify.constantize

          # 提取条件
          cond, *_v = build_conditions(v, m, true)

          # 是否有明确指定（必须Join）的Model
          valid_models << m if v[:is_must_be_joined].to_i == 1
          
          unless cond.blank? # 条件为空的，不关联
            if v.include?(:join_assoc) # 是否有明确指定的Associations（Join）
              name = v[:join_assoc].to_sym
              cname = key_model.reflections[name].class_name
              if cname == m.name # 该关系对应的类和当前model一样
                specified_assocs[m.name] = name
              else # 该关系对应的类和当前model不一样，我们需要再深入一层！
                cname.constantize.reflections.each do | n, assoc |
                  specified_assocs[m.name] = { name => n } if assoc.class_name == m.name
                end
              end
            end
          end
          

          all_models << m
          next if cond.blank? # 没有任何条件，不算valid
          conditions << cond
          values += _v
          valid_models << m if m != raw_model # 否则会自己Join自己！
        end
      end
      

      return (conditions + values) if is_only_build_conditions

      class_names, associations, joined_models = valid_models.map{|a|a.name}, [], {}

      # 先Join明确指定的Associations
      specified_assocs.each{|k, v| associations << v; joined_models[k] = v }

      # STEP-1: Join，通过model上面的associations来反向查找对应的关系
      key_model.reflections.each do | name, assoc |
        cname = assoc.class_name rescue nil
        if !cname.blank? && !specified_assocs.include?(cname) && class_names.include?(cname)
          associations << name
          joined_models[cname] = name
        end
      end
      
      # (NOTE: 如果 models.size > associations.size, 说明某些表之间无法Join起来!)

      # STEP-2: 尝试以“其他Model”为中心继续Join剩余的表
      if valid_models.size > associations.size && is_enable_smart_joins
        joined_models.each do | cname, assoc_name |
          sub_associations = []
          cname.constantize.reflections.each do | name, assoc |
            cname = assoc.class_name rescue nil
            if !cname.blank? && class_names.include?(cname) && !joined_models.keys.include?(cname)
              sub_associations << name
            end
          end
          associations << { assoc_name => sub_associations }
        end
      end
      
      # STEP-3: 我们尝试以 orders 为中心Join其他表
      if valid_models.size > associations.size && is_enable_smart_joins
        if raw_model != PgOrder # && raw_model.reflections.include?(:order)
          ref = raw_model.reflections.include?(:order) ? :order : :orders
          sub_associations = []
          PgOrder.reflections.each do | name, assoc |
            cname = assoc.class_name rescue nil
            sub_associations << name if !cname.blank? && class_names.include?(cname) && cname != "PgOrder"
          end
          #associations << {ref => sub_associations} unless sub_associations.blank?
        end
      end

      # Join!
      if associations.present?
        scope = key_model.joins(*associations)
      else
        scope = key_model
      end
      scope = scope.where([conditions.join(' AND ')] + values)
      scope = scope.page(params[:page]||1).per_page(params[:per]||20) if params[:all].blank? # pagination
      scope = scope.order(params[:order]||"#{key_model.table_name}.id DESC") # order by
      is_debug ? scope.to_sql : scope

    end

    VALID_PREFIX = '__less_|__more_|__min_|__max_|__diy_|__like_|__find_in_set_'

    def build_conditions(params, model, with_prefix = false)
      return '' if params.blank?
      params = params.dup.delete_if { |k,v| (!(/#{VALID_PREFIX}/ =~ k) && !model.column_names.include?(k)) || v.blank? } # cleanup params
      columns, values = [], []
      params.each do | k, v |
        prefix, _column = k.scan(/^(#{VALID_PREFIX})?([\w]+)/)[0]
        v = v.is_a?(String) ? v.strip : v
        column = with_prefix ? "#{model.table_name}.#{_column}" : _column
        case prefix
        when /__less_/
          columns << "#{column} < ?"
          values << v
        when /__more_/
          columns << "#{column} > ?"
          values << v
        when /__min_/
          columns << "#{column} >= ?"
          values << v
        when /__max_/
          columns << "#{column} <= ?"
          if v =~ EXPR_DATE && model.columns_hash[_column].type == :datetime
            v = Time.parse(v).strftime("%Y-%m-%d 23:59:59")
          end
          values << v
        when /__diy_/
          columns << "(#{v})"
        when /__like_/
          if v.is_a?(Array)
            columns << '(' + (["#{column} LIKE ?"]*v.size).join(' OR ') + ')'
            values += v.map{|a|"%#{a}%"}
          else
            columns << "#{column} LIKE ?"
            values << "%#{v}%"
          end
        when /__find_in_set_/
          if v.is_a?(Array)
            columns << '(' + (["FIND_IN_SET(?, #{column})"]*v.size).join(' OR ') + ')'
            values += v
          else
            columns << "FIND_IN_SET(?, #{column})"
            values << v
          end
        else
          #v = v.scan(/\d+/)[0].to_i if v.is_a?(String) && column =~ /^`?id`?$|\.`?id`?$/ # id column
          v = v.split(',') if v =~ /^[\d, ]+$/
          columns << (v.is_a?(Array) ? "#{column} IN (?)" : "#{column} = ?")
          values << v
        end
      end
      sql = [columns.join(' AND ')] + values
    end

    def search(params)

      puts "--- 不推荐使用Util.search(...)，下个版本将会废弃! 请使用Util.search2(...) ---"

      # TODO, document here!
      return_model = params[:models][0].table_name.classify.constantize
      master_model = params[:models][1].table_name.classify.constantize rescue params[:models][1] # v_orders cann't reverse to the model
      has_db_view = (!master_model.blank? && master_model.table_name =~ /v_/)
      pagination_model = has_db_view ? params[:models][1] : params[:models][0]

      if params[:models].size == 1 || has_db_view # Single table here || db view

        t = params["table_#{pagination_model.table_name}"]
        params.merge!(t) unless t.blank?
        conditions = build_conditions(params, pagination_model)
        scope = pagination_model.where(conditions.size == 1 ? conditions[0] : conditions)

      else                          # Multi tables

        models, conditions, where_values = [master_model, return_model], [], [], []

        conditions << join_models(master_model, return_model) # order_wrongs.order_id = order.id

        params.each do | k, v |
          if /__diy_/ =~ k
            conditions << v
          else
            prefix, table_name = k.split('table_')
            next if table_name.blank?
            model = table_name.classify.constantize
            a, *b = build_conditions(v, model, true)
            next if a.blank?
            conditions << a; where_values += b
            models << model
          end
        end

        models.uniq!
        models.each do | model |
          next if model == master_model || model == return_model
          condition = join_models(model, master_model)
          condition = join_models(model, return_model) if condition.blank?
          conditions << condition
        end

        scope = pagination_model.from(models.map{|m|m.table_name}.join(', ')).where([conditions.join(' AND ')] + where_values)

      end

      scope = scope.select("#{pagination_model.table_name}.id")
      scope = scope.page(params[:page]||1).per(params[:per]) unless params[:per].blank? # pagination
      scope = scope.order(params[:order_by]) unless params[:order_by].blank?  # order by
      scope = scope.group(params[:group_by]) unless params[:group_by].blank?  # group by

      ids = scope.map{|o|o.id}
      ids = [-999] if ids.blank? # 为了返回Relation对象同时又不爆掉！

      {
        :pagination => scope,
        :items => return_model.where(["id IN (?)", ids]).order("FIELD (id, #{ids.join(',')})")
      }

    end

    # 生成随机数
    def rand_code(num = 6)
      Array.new(num){rand(0..9)}.join()
    end

    # 默认返回未来56天的日期以及day_name
    # e.g.: {"2014-08-22" => "星期五", "2014-08-23" => "星期六"}
    def calculate_date_and_days(start_day=Date.today, end_day=Date.today + 55.days)
      start_day = Date.parse(start_day.to_s)
      end_day   = Date.parse(end_day.to_s)
      date_and_day_name = {}
      (start_day..end_day).each do |date|
        date_and_day_name[date.to_s] = I18n.l(date, format: "%A")
      end
      date_and_day_name
    end

    # v3数据库保存默认Sender
    def merge_sender(params)
      sender = { "Created" => Time.now, "CreatedBy" => OPERATOR, "ModifiedBy" => OPERATOR, "Modified" => Time.now }
      params.merge!(sender)
    end

    # 生成新的uuid
    def new_uuid
      SecureRandom.uuid
    end

    # 门店系统 v3数据库保存默认Sender
    def merge_store_sender(params)
      sender = { "Created" => Time.now, "CreatedBy" => STORE_OPERATOR, "ModifiedBy" => STORE_OPERATOR, "Modified" => Time.now }
      params.merge(sender)
    end

    # 下拉框显示年份
    def select_years
      years = []
      SELECT_YEARS.times do |y|
        years << Time.now.year - SELECT_YEARS/2.round + y
      end
      years
    end
    
    # 判断是否周末
    def is_weekend?(current_date, start_at, end_at)
      is_weekend = false
      # 不能为空
      return false if start_at.blank? || end_at.blank?
      # 不在星期内，直接返回false
      return false unless start_at.between?(0, 6) && end_at.between?(0, 6)
      
      # 如果current_date是周末,直接返回
      return true if current_date.wday == start_at
      
      begin
        start_at += 1
        start_at %= 7
        is_weekend = true if current_date.wday == start_at
      end until start_at == end_at
      is_weekend
    end

    # 获取节假日 
    # => 当前日期： current_date
    # => 节假日开始时间： params[:HOLIDAY_start_at],HOLIDAY是HOLIDAY_LIST的key
    # => 节假日结束时间： params[:HOLIDAY_end_at]
    def get_holiday(current_date, params)
      HOLIDAY_LIST.each do |k, v|
        start_at = Time.parse(params[(k + "_start_at").to_sym]) rescue next
        end_at = Time.parse(params[(k + "_end_at").to_sym]) rescue next
        return v if current_date.between?(start_at, end_at)
      end
      nil
    end

    # 将Array对象元素 按照树状结构进行排序
    # @param 对象数组 array
    # @param 根节点或者某个父节点 parent
    # @param 参数对象 options{parent_id:"",order_num:""} 
    # parent_id 父id字段 默认 "parent_id" order_num 根据指定字段排序 默认 "order_num" 
    def tree_sort(array, parent, options = {})
      options = {parent_id: "parent_id", order_num: "order_num" }.merge(options)
      sort_array = [parent]
      children = array.select{|temp| temp[options[:parent_id].to_sym] == parent[:id]}.sort_by(&options[:order_num].to_sym)
      children.each do |object|
        sort_array << tree_sort(array, object, options)
      end
      sort_array.flatten
    end

    # 将时间格式化为 年-月-日 时：分：秒
    # @param 日期 date
    def get_datetime(date)
      date.strftime("%F %T")
    end

    private

    # 把时间字符串转换成时间对象
    def deep_wash!(params)
      deep_wash_for_array!(params) if params.is_a?(Array)
      deep_wash_for_hash!(params) if params.is_a?(Hash)
    end

    def deep_wash_for_array!(params)
      params.each_with_index do | v, i |
        params[i] = convert_string(v)
        deep_wash!(v)
      end
    end

    def deep_wash_for_hash!(params)
      params.dup.each do | k, v |
        params.delete(k)
        params[convert_string(k, true)] = convert_string(v)
        deep_wash!(v)
      end
    end

    EXPR_DATETIME   = /^\d{4}-\d+-\d+[ T]\d+:\d+/
    EXPR_DATE       = /^\d{4}-\d+-\d+$/
    EXPR_FLOAT      = /^\d+\.\d+$/
    EXPR_INTEGER    = /^\d+$/

    def convert_string(s, to_sym = false)
      return s unless s.is_a?(String)
      case s.strip
      when EXPR_DATETIME
        s = Time.parse(s)
      when EXPR_DATE
        s = Date.parse(s)
      when EXPR_FLOAT
        s = s.to_f
      when EXPR_INTEGER
        s = s.to_i
      else
        s = to_sym ? s.to_sym : s
      end
    end

    def join_models(a, b)
      if a.column_names.include?(b.name.foreign_key) # order_wrongs.order_id = order.id
        "#{a.table_name}.#{b.name.foreign_key} = #{b.table_name}.id"
      elsif b.column_names.include?(a.name.foreign_key)  # user.id = order.user_id
        "#{a.table_name}.id = #{b.table_name}.#{a.name.foreign_key}"
      else # A --(B)--> C
        # TODO, order_wongs --(orders)--> users
        ''
      end
    end
  end
end

# 在helper里面include CoreHelper，即可在Controller、View里面不带前缀使用！
module UtilHelper

  def cut(text, length = 20, tail = "...")
    Util.cut(text, length, tail)
  end

end


