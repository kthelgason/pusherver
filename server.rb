# coding: utf-8
require 'rubygems'
require 'date'
require 'eventmachine'
require './response'

PORT = 4444
STATICDIR = "static"

$messages = []

def hello(req, res)
  res.render_template "views/index.erb", {messages: $messages}
end

def message(req, res)
  $messages << {text: req}
  res.status = 201
  res.status_string = "Created"
end

request_handlers = {
  "/" => method(:hello),
  "/message" => method(:message)
}

class SimpleHandler < EM::P::HeaderAndContentProtocol
  attr_accessor :handlers

  def receive_request(headers, content)
    @headers = headers_2_hash headers
    parse_req_line headers.first
    puts "#{DateTime.now}\t#{@method} #{@uri}"
    response = HttpResponse.new
    begin
      @handlers.fetch(@uri).call(content, response)
      send_response(response)
    rescue KeyError
      # No handler, try serving from static dir
      full_path = STATICDIR + @uri
      if File.exist? full_path
        response.serve_static(full_path)
        send_response(response)
      else
        # Resource not found
        send_response(response.not_found)
      end
    end
  end

  def parse_req_line(line)
    parsed = line.split(' ')
    @method, uri, _ = parsed
    @uri, @query = uri.split('?')
  end

  def send_response(res)
    send_data res
    close_connection_after_writing
  end
end

EventMachine.run do
  EventMachine::start_server '0.0.0.0', PORT, SimpleHandler do |conn|
    conn.handlers = request_handlers
  end
  puts "Listening on port #{PORT}."
end
