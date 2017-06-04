require 'test_helper'

class KonwledgeControllerTest < ActionController::TestCase
  test "should get book" do
    get :book
    assert_response :success
  end

end
