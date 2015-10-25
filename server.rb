# coding: utf-8
require 'rubygems'
require 'date'
require 'eventmachine'

CRLF = "\r\n"
PORT = 4444
STATICDIR = "static"

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
    puts "#{DateTime.now}\t#{@method} #{@uri}"
    begin
      handler = @handlers.fetch @uri
      send_response(200, "OK", handler.call)
    rescue KeyError
      # No handler, try serving from static dir
      full_path = STATICDIR + @uri
      if File.exist? full_path
        File.open full_path, "r" do |f|
          send_response(200, "OK", f.read)
        end
      else
        # Resource not found
        send_response(404, "Not Found")
      end
    end
  end

  def parse_req_line(line)
    parsed = line.split(' ')
    @method, uri, _ = parsed
    @uri, @query = uri.split('?')
  end

  def send_response(code, text, response="", content_type: "text/plain")
    send_data "HTTP/1.1 #{code} #{text}#{CRLF}" +
              "Content-type: #{content_type}#{CRLF}" +
              "Connection: close#{CRLF}" +
              "Content-length: #{response.bytesize + 2}#{CRLF}" +
              CRLF + response + CRLF
    close_connection_after_writing
  end
end


EventMachine.run do
  EventMachine::start_server '0.0.0.0', PORT, SimpleHandler do |conn|
    conn.handlers = request_handlers
  end
  puts "Listening on port #{PORT}."
end
