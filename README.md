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

## Usage

RackMotion borrows from Rack the concepts of both *applications* and *middleware*.

### Applications

In RackMotion, an application is anything that responds to `#call(request)` with the "HTTP triplet": the **status**, the **headers**, and the **body**. This could be a class:

    class RubyMotionTimespan
      def call(request)
        return [200, {'Content-Type' => 'text/plain'}, "RubyMotion Forever!".to_data]
      end
    end

Or, it could be a method:

    def ruby_motion_timespan(request)
      return [200, {'Content-Type' => 'text/plain'}, "RubyMotion Forever!".to_data]
    end

It can even be just a plain old lambda:

    lambda { |request| [200, {'Content-Type' => 'text/plain'}, "RubyMotion Forever!".to_data] }

When an application is in place, all requests will end up there *instead* of going on to the outside world. This functionality is perfect for, say, implementing something like Matt Green's [WebStub](https://github.com/mattgreen/webstub).

To route requests to an application, the `RackMotion::run(app)` method is called at some point before the requests are made. The beginning of your AppDelegate's `applicationDidFinishLaunching:` method is a good choice. As an example, here's how each of the three applications from above would be setup:

    RackMotion.run RubyMotionTimespan.new

    RackMotion.run method(:ruby_motion_timespan)

    RackMotion.run lambda { |request| [200, {'Content-Type' => 'text/plain'}, "RubyMotion Forever!".to_data] }

Currently, only one application can be used at a time. Eventually, something more like [Rack::Builder](http://rack.rubyforge.org/doc/classes/Rack/Builder.html) will likely be implemented.

### Middleware

In RackMotion, middleware is a special type of application. Like an application, all middleware responds to `#call(request)` with the "HTTP triplet" (the **status**, the **headers**, and the **body**). The difference, then, is that middleware also have an initializer that takes another application as an argument. This application can then be called during the middleware's `#call(request)` method to "send the request on down the line", if you will.

Here's an example:

    class AutocompleteTakeover
      def initialize(app)
        @app = app
      end
      
      def call(request)
        status, headers, data = @app.call(request)
        
        if request.URL.absoluteString.start_with? 'http://clients1.google.com/complete/search?'
          if data.to_s.start_with?('window.google.ac.h(') && data.to_s.end_with?(')')
            json = BW::JSON.parse(data.to_s[19..-2])
            json[1].map! { |e| ['RubyMotion Forever!', e[1]] }
            data = "window.google.ac.h(#{BW::JSON.generate(json)})".to_data
          end
        end
        
        return status, headers, data
      end
    end

The above piece of middleware intercepts and alters the communications used for the autocomplete feature on [google.com](http://google.com). Keep in mind that UIWebViews use NSURLConnection for their HTTP requests, ***even for JavaScript***, and that all NSURLConnections are intercepted by RackMotion.

To use middleware, the `RackMotion::use(middleware)` method is called at some point before the requests are made. Just as with applications, the beginning of your AppDelegate's `applicationDidFinishLaunching:` method is a good choice.

As an example:

    RackMotion.use AutocompleteTakeover

Unlike applications, you're already free to use as many middlewares as you'd like.

## Contributing

Everyone should feel free to send pull requests. It would be wonderful to see this project grow into something bigger.
