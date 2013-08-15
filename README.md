<p align="center">
  <img src="https://raw.github.com/drewbug/RackMotion/assets/rackmotion-logo.png" alt="RackMotion" title="RackMotion">
</p>

RackMotion provides a Rack-like interface for middleware that can intercept and alter HTTP requests and responses in RubyMotion. It's built on top of NSURLProtocol, which makes it, to borrow a line from [Mattt Thompson](http://www.nshipster.com/nsurlprotocol/), an Apple-sanctioned man-in-the-middle attack.

For example, here's how easy it is to enable [cross-origin resource sharing](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) for most Javascript XMLHttpRequests:

    class EnableCORS
      def initialize(app)
        @app = app
      end
      
      def call(request)
        status, headers, data = @app.call(request)
        
        if request.allHTTPHeaderFields['Origin']
          headers['Access-Control-Allow-Origin'] = request.allHTTPHeaderFields['Origin']
        end
        
        return status, headers, data
      end
    end

And then, in your AppDelegate:

    RackMotion.use EnableCORS

## Installation

Add this line to your application's Gemfile:

    gem 'RackMotion'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install RackMotion
