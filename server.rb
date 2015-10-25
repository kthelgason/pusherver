# coding: utf-8
require 'rubygems'
require 'date'
require 'eventmachine'
require 'erb'

CRLF = "\r\n"
PORT = 4444
STATICDIR = "static"

def hello
  render_template "views/index.erb", {messages: []}
end

request_handlers = {
  "/" => method(:hello)
}

class StaticFile
  CONTENT_TYPES = {
    "js" => "application/javascript",
    "html" => "text/html",
    "css" => "text/css"
  }
  def initialize(filename)
    @filename = filename
    @extention = filename.split('.').last
  end

  def read
    File.open @filename, "r" do |f|
      f.read
    end
  end

  def content_type
    CONTENT_TYPES.fetch(@extention, "text/plain")
  end
end


class SimpleHandler < EM::P::HeaderAndContentProtocol
  attr_accessor :handlers
  def receive_request(headers, content)
    @headers = headers_2_hash headers
    parse_req_line headers.first
    puts "#{DateTime.now}\t#{@method} #{@uri}"
    begin
      content, content_type = @handlers.fetch(@uri).call
      send_response(200, "OK", content, content_type: content_type)
    rescue KeyError
      # No handler, try serving from static dir
      full_path = STATICDIR + @uri
      if File.exist? full_path
        file = StaticFile.new full_path
        send_response(200, "OK", file.read, content_type: file.content_type)
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
              "Server: Pusherver 0.0.2#{CRLF}" +
              "Content-type: #{content_type}#{CRLF}" +
              "Connection: close#{CRLF}" +
              "Content-length: #{response.bytesize + 2}#{CRLF}" +
              CRLF + response + CRLF
    close_connection_after_writing
  end
end

def render_template(tmpl, mapping)
  page = ""
  b = binding
  mapping.each do |k,v|
    b.local_variable_set(k, v)
  end
  File.open tmpl, "r" do |f|
    page = ERB.new(f.read()).result(b)
  end
  return page, "text/html"
end

EventMachine.run do
  EventMachine::start_server '0.0.0.0', PORT, SimpleHandler do |conn|
    conn.handlers = request_handlers
  end
  puts "Listening on port #{PORT}."
end
