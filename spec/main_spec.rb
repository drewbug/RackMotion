class MirrorApp
  def call(request)
    raw = { url: request.URL.absoluteString,
            headers: request.allHTTPHeaderFields,
            body: request.HTTPBody }
    json = BW::JSON.generate(raw)
    return 200, {}, json.to_data
  end
end

class TestWare
  def initialize(app)
    @app = app
  end

  def call(request)
    request.addValue('true', forHTTPHeaderField: 'TestWare-Request')

    status, headers, data = @app.call(request)

    headers['TestWare-Response'] = 'true'

    return status, headers, data
  end
end

describe "Middleware" do
  before do
    RackMotion.run MirrorApp.new
    RackMotion.use TestWare

    connection_delegate = RackMotion::ConnectionDelegate.new

    @thread = NSThread.alloc.initWithTarget(lambda do
      request = NSURLRequest.requestWithURL NSURL.URLWithString('http://example.com')
      @connection = NSURLConnection.alloc.initWithRequest(request, delegate: connection_delegate, startImmediately: true)
      NSRunLoop.currentRunLoop.run
    end, selector: 'call', object: nil)
    @thread.start

    connection_delegate.semaphore.wait

    @status = connection_delegate.response.statusCode
    @headers = connection_delegate.response.allHeaderFields
    @body = BW::JSON.parse connection_delegate.data
  end

  it "can add a request header" do
    @body[:headers]['TestWare-Request'].should.be == 'true'
  end

  it "can add a response header" do
    @headers['TestWare-Response'].should.be == 'true'
  end

  after do
    @connection.cancel if @connection
    @thread.cancel if @thread

    @connection = @thread = @status = @headers = @body = nil

    RackMotion.cease
  end
end
