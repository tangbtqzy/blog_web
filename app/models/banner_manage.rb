class BannerManage < ActiveRecord::Base
  mount_uploader :img_url, AvatarUploader
  # validates :activity_name, :img_url, :link_url, presence: true
end
