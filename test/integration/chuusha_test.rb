require 'test_helper'

class ChuushaTest < Test::Unit::TestCase
  SUPPORT_DIR = File.dirname(__FILE__) + '/../support'
  PUBLIC_DIR  = SUPPORT_DIR + '/public'

  include Rack::Test::Methods

  def app
    app = Rack::Builder.new {
      use Chuusha::Rack, PUBLIC_DIR, SUPPORT_DIR + "/config.yml"
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

  test "should return the correct mime-type" do
    get "/application.js"
    assert_equal Rack::Mime.mime_type(".js"), last_response.headers["Content-Type"]

    get "/application.css"
    assert_equal Rack::Mime.mime_type(".css"), last_response.headers["Content-Type"]
  end

  test "it should always cache templates on load if rails is around" do
    cached_file = PUBLIC_DIR + "/application.css"

    begin
      ENV['RAILS_ENV'] = 'development'
      get "/"
      assert File.exist?(cached_file), "Expected a cache file"
      assert_equal "p { color: #000; }\n", File.read(cached_file)
    ensure
      ENV['RAILS_ENV'] = nil
      File.delete(cached_file) if File.exist?(cached_file)
    end
  end

  test "it should always cache templates if rails is around" do
    cached_file = PUBLIC_DIR + "/application.css"

    begin
      ENV['RAILS_ENV'] = 'development'
      get "/"
      mtime = File.mtime(cached_file)

      sleep 1 # sleeping is the easiest way to get the mtime to change
      get "/application.css"
      assert_not_equal mtime, File.mtime(cached_file)
    ensure
      ENV['RAILS_ENV'] = nil
      File.delete(cached_file) if File.exist?(cached_file)
    end
  end

  test "should allow override of cached envs" do
    cached_file = PUBLIC_DIR + "/application.css"

    # redefining app to overcome overriding of cached envs
    app = Rack::Builder.new {
      use Chuusha::Rack, PUBLIC_DIR, { "cache" => { "envs" => ["staging"],
                                                    "on_load" => false },
                                       "variables" => { "black" => "#000" }}
      run Proc.new { |env| [200, {}, "hi"] }
    }

    session = Rack::Test::Session.new(Rack::MockSession.new(app))

    begin
      session.get "/application.css"
      assert !File.exist?(cached_file)

      ENV['RACK_ENV'] = 'staging'
      session.get "/application.css"
      assert File.exist?(cached_file), "Expected a cache file"

      assert_equal "p { color: #000; }\n", File.read(cached_file)
    ensure
      ENV['RACK_ENV'] = 'test'
      File.delete(cached_file) if File.exist?(cached_file)
    end
  end

  test "should cache templates on load by default in production" do
    cached_files = [ PUBLIC_DIR + "/application.css",
                     PUBLIC_DIR + "/application.js" ]

    # redefining app to overcome overriding of cached envs
    app = Rack::Builder.new {
      use Chuusha::Rack, PUBLIC_DIR, { "variables" => { "black" => "#000" }}
      run Proc.new { |env| [200, {}, "hi"] }
    }

    begin
      with_request(app, cached_files) do |file|
        assert File.exist?(file)
      end
    ensure
      ENV['RACK_ENV'] = 'test'
      cached_files.each do |file|
        File.delete(file) if File.exist?(file)
      end
    end
  end

  test "should not cache templates on load if specified" do
    cached_files = [ PUBLIC_DIR + "/application.css",
                     PUBLIC_DIR + "/application.js" ]

    app = Rack::Builder.new {
      use Chuusha::Rack, PUBLIC_DIR, { "cache" => { "on_load" => false },
                                       "variables" => { "black" => "#000" }}
      run Proc.new { |env| [200, {}, "hi"] }
    }

    begin
      with_request(app, cached_files) do |file|
        assert !File.exist?(file)
      end
    ensure
      ENV['RACK_ENV'] = 'test'
      cached_files.each do |file|
        File.delete(file) if File.exist?(file)
      end
    end
  end

  test "should cache files to alternate output dir when directed" do
    cached_files = [ PUBLIC_DIR + "/application.css",
                     PUBLIC_DIR + "/application.js" ]

    output_dir = "/tmp/chuusha"

    # redefining app to overcome overriding of cached envs
    app = Rack::Builder.new {
      use Chuusha::Rack,
          PUBLIC_DIR,
          { "variables" => { "black" => "#000" }},
          output_dir
      run Proc.new { |env| [200, {}, "hi"] }
    }

    begin
      with_request(app, cached_files) do |file|
        path = "#{output_dir}/#{File.basename(file)}"
        assert File.exist?(path), "Failed to cache file at #{path}"
      end

    ensure
      ENV['RACK_ENV'] = 'test'
      cached_files.each do |file|
        File.delete(file) if File.exist?(file)
      end
      FileUtils.rm_rf(output_dir)
    end
  end

  test "the config file should be optional" do
    chuusha = Chuusha::Rack.new(nil, PUBLIC_DIR)
    resp = chuusha.call({"PATH_INFO" => '/no_config.css'})
    assert_equal "p { color: #00f; }\n", resp.last
  end

  def with_request(app, cached_files)
    session = Rack::Test::Session.new(Rack::MockSession.new(app))

    ENV['RACK_ENV'] = 'production'

    session.request '/' # gotta hit it once to init things
    cached_files.each do |file|
      yield file
    end
  end
end
