class MailerUtil < ActionMailer::Base
  default from: '384244804@qq.com'
  def  send comment
     @comment = comment
     #@comment 	= 'send email content'
     #@url 		= 'tangbt@reocar.com'
     @url = post_url(@comment.post, host: 'localhost')
     @touser	= 'tangbt@reocar.com'
     @subject	= 'subject title'
     mail to:  @touser,subject: @subject#,@comment
  end
end