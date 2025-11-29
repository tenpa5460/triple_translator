require "test_helper"

class TranslationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get translations_new_url
    assert_response :success
  end
end
