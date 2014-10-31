class Comment < ActiveRecord::Base

  validates :title, presence: true
  #self.create(title: "John Doe").valid? # => true
 # self.create(content: nil).valid? # => false

   #def new 
    #@result = Comments.new
  #end
  class << self
    
    def save params
       #print '23'
       #self.new params
      # validates :titlte, presence: true
       #self.create(title: "John Doe").valid? # => true
       #self.create(content: nil).valid? # => false
       @result = self.create params
       #@resutl = saveinfo params
    end

     # get all information
    def getall
      @result = self.all
    end

    # get comment info by id
    def detail params
        self.find(params)
    end
    
    # present not use
    def saveinfo params
      @result = Comment.save(params)
    end
  end
end
