$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "winnow/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "winnow"
  s.version     = Winnow::VERSION
  s.authors     = ["Brad Wilson"]
  s.email       = ["brad.wilson@blake.com.au"]
  s.homepage    = ""
  s.summary     = "Form based searching for Rails."
  s.description = "Form based searching for Rails."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", [">= 3.0.0", "< 7.1.0"]
end
