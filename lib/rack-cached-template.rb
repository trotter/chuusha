require 'rubygems'
require 'yaml'
require 'erubis'

module Rack
  class CachedTemplates
    def initialize(app, config, root_dir)
      @app      = app
      @root_dir = root_dir
      @config   = Config.new(config)
    end

    def call(env)
      renderer = Renderer.new(@config, @root_dir, env)
      return renderer.respond if renderer.template_exists?
      @app.call(env)
    end
  end

  class Config
    attr_reader :variables

    def initialize(file)
      @variables = YAML.load_file(file)
    end
  end

  class Renderer
    def initialize(config, root_dir, env)
      @config = config
      @path = root_dir + env["PATH_INFO"] + ".erb"
    end

    def template_exists?
      ::File.exist?(@path)
    end

    def render
      eruby = Erubis::Eruby.new(::File.read(@path))
      eruby.result(@config.variables)
    end

    def respond
      # TODO: Should get right content-type
      [200, {"Content-Type" => "text/html"}, render]
    end
  end
end
