class TestWare
  def initialize(app)
    @app = app
  end

  def call(request)
    status, headers, data = @app.call(request)

    headers['TestWare'] = 'true'
    status = 203

    return status, headers, data
  end
end

describe "Middleware 'TestWare'" do
  extend WebStub::SpecHelpers

  before do
    stub_request(:get, 'http://example.com').to_return(body: "Success!", content_type: 'text/plain')
    RackMotion.use TestWare

    @response = nil
    BW::HTTP.get('http://example.com') do |response|
      @response = response
      resume
    end
  end

  it "adds a 'TestWare' response header" do
    wait_max(10) do
      @response.headers['TestWare'].should == 'true'
    end
  end

  it "makes response status code '203'" do
    wait_max(10) do
      @response.status_code.should == 203
    end
  end

  after do
    RackMotion.cease_all
    reset_stubs
  end
end
