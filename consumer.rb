require 'rubygems'
require 'bundler'
Bundler.require

require "oauth/consumer"

enable :sessions

CONFIG = YAML.load("config.yml")

before do
  session[:oauth] ||= {}
  consumer_key = CONFIG[:key]
  consumer_secret = CONFIG[:secret]
  
  @consumer ||= OAuth::Consumer.new( consumer_key, consumer_secret , {
      :site=>CONFIG[:host]
      #:authorize_path => "/oauth/request_token", 
      #:access_token_path => "/oauth/access_token",
      #:authorize_path =>"/oauth/authorize"
  })
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end
end

get "/" do
  if @access_token
    @data= @access_token.get('/causes.xml')
    @data = @data.body
    haml :index
  else
    '<a href="/request">Sign On</a>'
  end
end

get "/request" do
  @request_token = @consumer.get_request_token(:oauth_callback => "http://#{request.host}/auth")
  session[:oauth][:request_token] = @request_token.token
  session[:oauth][:request_token_secret] = @request_token.secret
  redirect @request_token.authorize_url
end

get "/auth" do
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end