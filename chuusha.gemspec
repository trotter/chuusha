PKG_VERSION = "0.1.0"
PKG_FILES   = Dir['README',
                  'lib/**/*.rb']

$spec = Gem::Specification.new do |s|
  s.name = 'chuusha'
  s.version = PKG_VERSION
  s.summary = "Run templates through erb and cache the resulting static file"
  s.description = <<EOS
  Chuusha allows you to evaluate both javascript and css templates 
  within the same context, meaning that you can share constants between the
  templates.
EOS

  s.add_dependency("rack", ">= 1.1.0")
  s.files       = PKG_FILES.to_a
  s.has_rdoc    = false
  s.author      = "Trotter Cashion"
  s.email       = "cashion@gmail.com"
  s.homepage    = "http://trottercashion.com"
end
