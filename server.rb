# coding: utf-8
require 'rubygems'
require 'date'
require 'eventmachine'
require './response'

PORT = 4444
STATICDIR = "static"

$messages = []
$conns = []

def hello(conn, req, res)
  res.render_template "views/index.erb", {messages: $messages}
end

def message(conn, req, res)
  $messages << {text: req}
  res.status = 201
  res.status_string = "Created"
  $conns.each {|c| c.send_streaming_data "data: #{req}\r\n\r\n" }
end

def stream(conn, req, res)
  $conns << conn
  res.headers["Content-type"] = "text/event-stream"
  conn.is_streaming = true
  conn.send_streaming_data res.stream_headers
end

request_handlers = {
  "/" => method(:hello),
  "/message" => method(:message),
  "/stream" => method(:stream)
}

class SimpleHandler < EM::P::HeaderAndContentProtocol
  attr_accessor :handlers, :is_streaming
  def post_init
    @is_streaming = false
  end

  def receive_request(headers, content)
    @headers = headers_2_hash headers
    parse_req_line headers.first
    puts "#{DateTime.now}\t#{@method} #{@uri}"
    response = HttpResponse.new
    begin
      @handlers.fetch(@uri).call(self, content, response)
      send_response(response) unless @is_streaming
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

  def unbind
    puts "Client disconnected"
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

  def send_streaming_data(string)
    send_data string
  end
end

EventMachine.run do
  EventMachine::start_server '0.0.0.0', PORT, SimpleHandler do |conn|
    conn.handlers = request_handlers
  end
  puts "Listening on port #{PORT}."
end
