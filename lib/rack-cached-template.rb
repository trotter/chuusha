module Rack
  class CachedTemplates
    def initialize(app, root_dir)
      @app = app
      @root_dir = root_dir
    end

    def call(env)
      renderer = Renderer.new(@root_dir, env)
      return renderer.respond if renderer.template_exists?
      @app.call(env)
    end
  end

  class Renderer
    def initialize(root_dir, env)
      @path = root_dir + env["PATH_INFO"] + ".erb"
    end

    def template_exists?
      ::File.exist?(@path)
    end

    def render
      ::File.read(@path)
    end

    def respond
      # TODO: Should get right content-type
      [200, {"Content-Type" => "text/html"}, render]
    end
  end
end
