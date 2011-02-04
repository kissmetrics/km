#!/usr/bin/env ruby
require 'socket'
require 'rubygems'
require 'json'
require 'uri'
require 'cgi'

# a library to accept connections as a server, and send back what it received on request.

class Accept
  attr_accessor :server, :session
  attr_reader :opts
  URI_REXEGP = /^\s*(\w+)\s+([^ ]*)\s+(.*)$/
  def initialize(args = {})
    opts = { :port => 9292, :debug => false }
    opts.update(args)

    puts "Starting up server on port #{opts[:port]} ..."
    @opts           = opts
    @server         = TCPServer.new(opts[:port])
    @@input_history = []
    @handle         = Thread.start do
      while (@session = server.accept)
        Thread.start do
          # puts "log: Connection from #{session.peeraddr[2]} at #{session.peeraddr[3]}"
          # session.puts "Server: Connection from #{session.peeraddr[2]}\n"
          handle_input
          session.close
        end
      end
    end
  end
  def input_history
    @@input_history
  end
  def wait
    @handle.join
  end

  def handle_input
    input = session.gets
    if input
      puts "received: #{input.inspect}" if opts[:debug]
      case input
      when /clear/
        clear
      when /history/
        session.puts input_history.to_json
      when /exit/
        begin
          close
        rescue Exception
        end
        return
      when /^\s*(GET|POST|PUT|DELETE)\s+([^ ]*)\s+(.*)$/
        @@input_history << parse_input(input)
      else
        @@input_history << input.chomp
      end
    end
  end
  def parse_input(input)
    data = {}
    data[:raw] = input.chomp
    (method,uri,http) = input.scan(/^\s*(\w+)\s+([^ ]*)\s+(.*)$/).flatten

    data[:method] = method
    data[:http] = http.chomp
    data[:uri] = uri
    u = URI(uri)
    data[:path] = u.path
    data[:query] = CGI.parse(u.query)
    return data
  end
  def close
    session = nil
    server.close
  end
  # clear history
  def clear
    @@input_history.clear
  end
end
__END__
% ruby -r './lib/ruby/accept.rb' -e 'Accept.new(:debug => true, :port => 9292).wait'
Starting up server on port 9292 ...

echo rain | nc localhost 9292
% echo history | nc localhost 9292
["rain"]
