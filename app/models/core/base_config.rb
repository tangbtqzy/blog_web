# encoding = utf-8
class BaseConfig
  IP_ADDRESS 	= '127.0.0.1'
  PORT		        = '5432'
  PASSWORD	= 'postgres'
  USERNAME	='postgres'
  DATABASE	        = 'testdb'
  DRIVER	        = 'postgresql'
  POOL		        = 5

   class << self

     def  getip
      IP_ADDRESS
     end
      
      def port
        PORT
      end

      def pwd
        PASSWORD
      end

      def name
         USERNAME
      end

      def sendmail
        @account = IP_ADDRESS
        MailerUtil.send(@account).deliver
      end

   end
end