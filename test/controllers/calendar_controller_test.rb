require 'test_helper'

class CalendarControllerTest < ActionController::TestCase
  test "should get only:show" do
    get :only:show
    assert_response :success
  end

end
