# encoding: utf-8
class HomeController < ApplicationController
  require "net/http"
  require "uri"
  before_action :create_params , only: [:create]
  def index
    url = URI.parse("http://image.baidu.com/channel/fashion")
    http = Net::HTTP.start(url.host, url.port)
    @doc = http.get(url.path)
    @banner = BannerManage.new
  end

  # save form
  def create
    if @banner_params.present?
      save_result = BannerManage.new(@banner_params)
    end
    if save_result.save
      render json: {code: true, message: "successed"}
    else
      render json: {code: false, message: "failure"}
    end
  end

  # upload file list
  def upfiles
    @files = BannerManage.all
    puts @files
  end

  
  private
    # filter params
    def create_params
      @banner_params = params.require(:banner_manage).permit(:title, :link_url, :img_url)
    end

end
