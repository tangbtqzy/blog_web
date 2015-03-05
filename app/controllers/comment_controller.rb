# encoding: utf-8
class CommentController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  # home page 
  def index
    @comment = Comment.new
    render layout: false
  end
  # create page
  def create
    #debugger
    print "author: tangbt testinfo/r/n"
    @comment = Comment.save getcreate
    #render  'comment/index'
    redirect_to '/comment'
    #render 'comment/list'
  end
 # del page
  def  del
  	
  end

   # show a product
   def show
      @getinfo = Digest::MD5.hexdigest(BaseConfig.getip) 
      # send email
      
      @commentdetail = Comment.detail params[:id]
   end

   # home page
  def home
    @comment_all = Comment.getall
    render 'comment/list'
  end

  # new page
  def  new

  end
  # edit page
  def edit

  end

  # update page
  def update 

  end 
  
  # get_content
  def get_content
    ur = "http://www.huawei.com/jp"
    Util.debug '&&&&&&&&&&&&&&&&'
    Util.debug f = open(ur)
    Util.debug f.charset
    Util.debug str = Nokogiri::HTML(f,nil,f.charset)
    Util.debug  str.encoding = "UTF-8"
    Util.debug script = str.xpath("//script").text.delete("\t").split("\n").delete("")
    Util.debug body = str.xpath("//body").text.delete("\t").split("\n").delete("")
    Util.debug '&&&&&&&&&&&&&&&&'
    get_data
  end

  private 

    def  getcreate
      @post = Post.find(params[:title])
      @comment = @post.comments.new(params[:comment])
      BaseConfig.sendmail
      params.require(:comment).permit(:title, :content)
    end

    def get_data
      require 'wombat'
      Wombat.crawl do
        base_url "https://www.github.com"
        path "/"

        headline xpath: "//h1"
        subheading css: "p.subheading"

        what_is({ css: ".one-half h3" }, :list)

        links do
          explore xpath: '//*[@class="wrapper"]/div[1]/div[1]/div[2]/ul/li[1]/a' do |e|
            binding.pry
            e.gsub(/Explore/, "Love")
          end

          features css: '.features'
          enterprise css: '.enterprise'
          blog css: '.blog'
        end
      end
    end
end
