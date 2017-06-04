require 'test_helper'

class ShareControllerTest < ActionController::TestCase
  test "should get konwledge" do
    get :konwledge
    assert_response :success
  end

  test "should get book" do
    get :book
    assert_response :success
  end

end
