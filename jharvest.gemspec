$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = %q{jharvest}
  s.version     = "0.0.1"
  s.date        = %q{2012-10-02}
  s.summary     = %q{Harvest Time Tracking API Client}
  s.description = %q{jharvest is a small wrapper for harvest's time traking api}
  s.authors     = ['José Corcuera']
  s.email       = 'jzcorcuera@gmail.com'
  s.files       = Dir['lib/**/*']
  s.require_paths = ["lib"]
end
