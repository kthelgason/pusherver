# coding: utf-8
require 'rubygems'
require 'erb'

class HttpResponse
  attr_accessor :status, :status_string, :content, :headers

  CONTENT_TYPES = {
    "js" => "application/javascript",
    "html" => "text/html",
    "css" => "text/css"
  }

  def initialize
    @headers = {
    "Server" => "Pusherver 0.0.2",
    "Connection" => "close"
    }
    @content = ""
  end

  def render_template(tmpl, mapping)
    b = binding
    mapping.each do |k,v|
      b.local_variable_set(k, v)
    end
    File.open tmpl, "r" do |f|
      @content = ERB.new(f.read()).result(b)
    end
    @headers["Content-type"] = "text/html"
  end

  def serve_static(filename)
    ext = filename.split('.').last
    File.open filename, "r" do |f|
      @content = f.read
    end
    @headers["Content-type"] = CONTENT_TYPES.fetch(ext, "text/plain")
  end

  def not_found
    @status = 404
    @status_string = "Not found"
  end

  def to_s
    string =  "HTTP/1.1 #{@status || 200} #{@status_string || "OK"}\r\n"
    @headers.each do |k,v|
      string << "#{k}: #{v}\r\n"
    end
    string << "Content-length: #{@content.bytesize + 2}\r\n"
    string << "\r\n"
    string << @content
    string << "\r\n"
  end

end
