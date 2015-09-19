# coding: utf-8
require 'sinatra'
require 'json'

set server: 'thin'

set :public_folder, File.dirname(__FILE__) + '/static'

messages = []

get '/' do
  erb :index, :locals => { messages: messages }
end

post '/message' do
  messages << JSON.parse(request.body.read)
  201
end

