
require "rubygems"
require "sinatra"
require "oauth"
require "oauth/consumer"
#require 'grackle'
require 'haml'

enable :sessions

before do
  session[:oauth] ||= {}
  
  consumer_key = "9MPIIyzbSYRQuAvJZlRLESI8LrQHuMBd3cBRBQur"
  consumer_secret = "NdikqpzEIK2CKhES9azsNZs1d2opQ9Xw9Xwv4mf5"
  
  
  @consumer ||= OAuth::Consumer.new( consumer_key, consumer_secret , {
      :site=>"http://localhost:3001"
      #, 
      #:authorize_path => "/oauth/request_token", 
      #:access_token_path => "/oauth/access_token",
      #:authorize_path =>"/oauth/authorize"
  })

  #@consumer ||= OAuth::Consumer.new(consumer_key, consumer_secret, :site => "http://localhost:3000")
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end
 
=begin  
  if @access_token
    @client = Grackle::Client.new(:auth => {
      :type => :oauth,
      :consumer_key => consumer_key,
      :consumer_secret => consumer_secret,
      :token => @access_token.token,
      :token_secret => @access_token.secret
    })
  end
=end

end

get "/" do
  if @access_token
    #@statuses = @client.statuses.friends_timeline? :count => 100
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

#22reIHqHY18ipUHChUMpyWmnEiREVHyoWVwOxxCp&oauth_verifier=BnJyRsvzTC5yxCk9jJkW

get "/auth" do
 # @request_token = @consumer.get_request_token(:oauth_callback => "http://artenlinea.cz/auth")
  
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end