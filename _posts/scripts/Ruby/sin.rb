require 'rubygems'
require 'sinatra'
require 'haml'

get '/' do 
	haml :index1
end
