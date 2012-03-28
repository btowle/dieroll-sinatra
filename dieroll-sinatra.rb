require 'sinatra'
require 'haml'
require './dieroll_restful.rb'
require './dieroll.rb'

get '/' do
  haml :index
end

get '/about' do
  haml :about
end
