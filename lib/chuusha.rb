require 'yaml'
require 'erubis'

module Chuusha
  class Rack
    def initialize(app, root_dir, config=nil)
      @app      = app
      @root_dir = root_dir
      @config   = Config.new(config)
      cache_everything if @config.cache_on_load?
    end

    def call(env)
      renderer = Renderer.new(@config, @root_dir + env["PATH_INFO"])
      return renderer.respond if renderer.template_exists?
      @app.call(env)
    end

    private
      def cache_everything
        template_files.each do |file|
          renderer = Renderer.new(@config, file)
          renderer.write_cached_copy
        end
      end

      def template_files
        Dir[@root_dir + "/**/*.erb"].map do |f|
          f.gsub(/\.erb$/, '')
        end
      end
  end

  class Config
    attr_reader :variables

    def initialize(file)
      @config     = file ? YAML.load_file(file) : {}
      @variables  = @config["variables"] || {}
      @cache      = @config["cache"] || {}
    end

    def cache_envs
      @cache["envs"] || []
    end

    def cache?
      env = ENV['RACK_ENV'] || ENV['RAILS_ENV']
      cache_envs.include?(env)
    end

    def cache_on_load?
      @cache["on_load"] && cache?
    end
  end

  class Renderer
    def initialize(config, path)
      @config = config
      @outfile = path
      @path = @outfile + ".erb"
      @evaluated = nil
    end

    def template_exists?
      ::File.exist?(@path)
    end

    def evaluated
      return @evaluated if @evaluated
      eruby = Erubis::Eruby.new(::File.read(@path))
      @evaluated = eruby.result(@config.variables)
    end

    def write_cached_copy
      ::File.open(@outfile, "w") { |f| f.write evaluated }
    end

    def render
      write_cached_copy if @config.cache?
      evaluated
    end

    def respond
      # TODO: Should get right content-type
      [200, {"Content-Type" => "text/html"}, render]
    end
  end
end
