# -*- encoding: utf-8 -*-
VERSION = "0.1"

Gem::Specification.new do |spec|
  spec.name          = "RackMotion"
  spec.version       = VERSION
  spec.authors       = ["Drew Carey Buglione"]
  spec.email         = ["me@drewb.ug"]
  spec.description   = %q{RackMotion provides a Rack-like interface for middleware that can intercept and alter HTTP requests and responses in RubyMotion. It's built on top of NSURLProtocol, which makes it, to borrow a line from Mattt Thompson, an Apple-sanctioned man-in-the-middle attack.}
  spec.summary       = %q{Intercept and alter HTTP requests and responses in RubyMotion}
  spec.homepage      = ""
  spec.license       = ""

  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files         = files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
end
