require 'test_helper'

class RackCachedTemplates < Test::Unit::TestCase
  SUPPORT_DIR = File.dirname(__FILE__) + '/../support'
  PUBLIC_DIR  = SUPPORT_DIR + '/public'

  include Rack::Test::Methods

  def app
    app = Rack::Builder.new {
      use Rack::CachedTemplates, SUPPORT_DIR + "/config.yml", PUBLIC_DIR
      run Proc.new { |env| [200, {}, "hi"] }
    }
  end

  test "should pass through when there is no template" do
    get "/"
    assert last_response.ok?
    assert_equal "hi", last_response.body
  end

  test "should render template when it exists" do
    get "/application.js"
    assert last_response.ok?
    assert_equal File.read(PUBLIC_DIR + "/application.js.erb"), last_response.body
  end

  test "should pass variables to template" do
    expected_resp = 
    get "/application.css"
    assert last_response.ok?
    assert_equal "p { color: #000; }\n", last_response.body
  end
end
