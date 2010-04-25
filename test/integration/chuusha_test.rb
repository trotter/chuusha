require 'test_helper'

class ChuushaTest < Test::Unit::TestCase
  SUPPORT_DIR = File.dirname(__FILE__) + '/../support'
  PUBLIC_DIR  = SUPPORT_DIR + '/public'

  include Rack::Test::Methods

  def app
    app = Rack::Builder.new {
      use Chuusha::Rack, SUPPORT_DIR + "/config.yml", PUBLIC_DIR
      run Proc.new { |env| [200, {}, "hi"] }
    }
  end

  setup do
    ENV['RACK_ENV'] = 'test'
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
    get "/application.css"
    assert last_response.ok?
    assert_equal "p { color: #000; }\n", last_response.body
  end

  test "should cache the template as specified by config" do
    cached_file = PUBLIC_DIR + "/application.css"
    begin
      get "/application.css"
      assert !File.exist?(cached_file)

      ENV['RACK_ENV'] = 'production'
      get "/application.css"
      assert File.exist?(cached_file)

      assert_equal "p { color: #000; }\n", File.read(cached_file)
    ensure
      ENV['RACK_ENV'] = 'test'
      File.delete(cached_file) if File.exist?(cached_file)
    end
  end

  test "should cache templates on boot if specified" do
    cached_files = [ PUBLIC_DIR + "/application.css",
                     PUBLIC_DIR + "/application.js" ]
    begin
      ENV['RACK_ENV'] = 'production'

      get '/' # gotta hit it one to init things
      cached_files.each do |file|
        assert File.exist?(file)
      end
    ensure
      ENV['RACK_ENV'] = 'test'
      cached_files.each do |file|
        File.delete(file) if File.exist?(file)
      end
    end
  end
end
