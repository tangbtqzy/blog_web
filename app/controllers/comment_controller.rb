# encoding: utf-8
class CommentController < ApplicationController
  
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

  private 
    def  getcreate
      @post = Post.find(params[:title])
      @comment = @post.comments.new(params[:comment])
      BaseConfig.sendmail
      params.require(:comment).permit(:title, :content)
    end
 
end
