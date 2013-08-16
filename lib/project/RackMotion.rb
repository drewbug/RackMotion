module RackMotion
  def self.use(middleware)
    NSURLProtocol.registerClass URLProtocol if URLProtocol.middlewares.empty?
    URLProtocol.middlewares << middleware
  end

  def self.cease(middleware)
    URLProtocol.middlewares.delete middleware
    NSURLProtocol.unregisterClass URLProtocol if URLProtocol.middlewares.empty?
  end

  def self.cease_all
    URLProtocol.middlewares = []
    NSURLProtocol.unregisterClass URLProtocol
  end

  class URLProtocol < NSURLProtocol
    @@middlewares = []

    def self.middlewares
      @@middlewares
    end

    def self.canInitWithRequest(request)
      return false unless request.URL
      return false unless request.URL.scheme.start_with?("http")
      !NSURLProtocol.propertyForKey('RackMotion', inRequest: request) 
    end

    def self.canonicalRequestForRequest(request)
      return request
    end

    def startLoading
      @thread = NSThread.alloc.initWithTarget(lambda do
        chain = @@middlewares.inject(self) do |instance, klass|
          klass.new(instance)
        end

        status, headers, data = chain.call self.request.mutableCopy

        response = NSHTTPURLResponse.alloc.initWithURL @connection.originalRequest.URL, statusCode: status, HTTPVersion: 'HTTP/1.1', headerFields: headers

        self.client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: NSURLCacheStorageNotAllowed)
        self.client.URLProtocol(self, didLoadData: data)
        self.client.URLProtocolDidFinishLoading(self)
      end, selector: 'call', object: nil)

      @thread.start
    end

    def stopLoading
      @connection.cancel if @connection
      @thread.cancel if @thread
    end

    def call(new_request)
      NSURLProtocol.setProperty(true, forKey: 'RackMotion', inRequest: new_request) 

      connection_delegate = ConnectionDelegate.new

      @connection = NSURLConnection.alloc.initWithRequest(new_request, delegate: connection_delegate, startImmediately: true)
      NSRunLoop.currentRunLoop.run
    
      connection_delegate.semaphore.wait
      return connection_delegate.response.statusCode, connection_delegate.response.allHeaderFields.mutableCopy, connection_delegate.data
    end
  end

  class ConnectionDelegate
    attr_reader :semaphore, :data, :response

    def initialize
      @semaphore = Dispatch::Semaphore.new(0)
      @data = NSMutableData.new
    end

    def connection(connection, didReceiveData: data)
      @data.appendData(data)
    end

    def connection(connection, didReceiveResponse: response)
      @response = response
    end

    def connectionDidFinishLoading(connection)
      @semaphore.signal
    end
  end
end
