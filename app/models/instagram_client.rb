class InstagramClient
  attr_accessor :delegate, :access_token

  API_URL = "https://api.instagram.com/v1/"

  def initialize(options = {})
  end

  def self.sharedClient
    Dispatch.once { @instance ||= new }
    @instance
  end

  def authenticate
    client_id = "9f9879ed9b384a369f32dac48ded9c6a"
    redirect_uri = "lovagram://instagram_callback"
    url = "https://instagram.com/oauth/authorize/?client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=token"

    UIApplication.sharedApplication.openURL(NSURL.URLWithString(url))
  end

  def handleOAuthCallBack(url)
    access_token_string = url[/access_token=(.*?)$/]
    access_token = access_token_string.split("=")[1]
    self.access_token = access_token
    ap "Access Token: #{self.access_token}"
  end

  def fetchFeed(tag)
    AFMotion::JSON.get(API_URL + "/users/self/media/recent", {count: 100, access_token: self.access_token}) do |response|
      handle_response(response, tag)
    end
  end

  private

  def handle_response(response, tag)
    if response.success?
      status_code = response.operation.response.statusCode
    else
      status_code = response.error.userInfo["AFNetworkingOperationFailingURLResponseErrorKey"].statusCode
    end
    
    method =  case status_code
              when 401
                :handle_auth_error
              when 200..299
                :handle_success
              when 500..599
                :handle_server_error
              end

    self.delegate.send(method, response, tag) if self.delegate.respond_to? method
  end
end
