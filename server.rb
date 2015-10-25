# coding: utf-8
require 'rubygems'
require 'eventmachine'

CRLF = "\r\n"
PORT = 4444


class SimpleHandler < EM::P::HeaderAndContentProtocol
  def receive_request(headers, content)
    @headers = headers_2_hash headers
    parse_req_line headers.first
    puts @uri
  end

  def parse_req_line(line)
    parsed = line.split(' ')
    @method, uri, _ = parsed
    @uri, @query = uri.split('?')
  end
end


EventMachine.run do
  EventMachine::start_server '0.0.0.0', PORT, SimpleHandler
  puts "Listening on port #{PORT}."
end
