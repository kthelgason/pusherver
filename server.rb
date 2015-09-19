# coding: utf-8
require 'sinatra'
require 'json'

set server: 'thin', connections: []

set :public_folder, File.dirname(__FILE__) + '/static'

messages = []


get '/' do
  erb :index, :locals => { messages: messages }
end

post '/message' do
  text = request.body.read
  settings.connections.each do |sock|
    sock << "data: #{text}\n\n"
  end
  201
end

get '/stream', provides: 'text/event-stream' do
  stream :keep_open do |sock|
    settings.connections << sock
    sock.callback { settings.connections.delete sock }
  end
end

