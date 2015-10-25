# coding: utf-8
require 'rubygems'
require 'eventmachine'

CRLF = "\r\n"
PORT = 4444

def hello
  return "Hello world!"
end

request_handlers = {
  "/" => method(:hello)
}

class SimpleHandler < EM::P::HeaderAndContentProtocol
  attr_accessor :handlers

  def receive_request(headers, content)
    @headers = headers_2_hash headers
    parse_req_line headers.first
    begin
      handler = @handlers.fetch @uri
      send_default_response handler.call
    rescue KeyError
    end
  end

  def parse_req_line(line)
    parsed = line.split(' ')
    @method, uri, _ = parsed
    @uri, @query = uri.split('?')
  end

  def send_default_response(response)
    send_data "HTTP/1.1 200 OK#{CRLF}" + 
              "Content-type: text/plain#{CRLF}" + 
              "Connection: close#{CRLF}" + 
              "Content-length: #{response.bytesize}#{CRLF}" +
              CRLF + response + CRLF + CRLF
    close_connection_after_writing
  end
end


EventMachine.run do
  EventMachine::start_server '0.0.0.0', PORT, SimpleHandler do |conn|
    conn.handlers = request_handlers
  end
  puts "Listening on port #{PORT}."
end
