require 'ap'
require 'km'
require 'fileutils'
require 'accept'

class KM
  class << self
    public :log_name, :reset, :log
  end
end

def __(*args)
  file_this_included_from = caller.first.split(":").first
  app_root = File.expand_path(File.dirname(file_this_included_from))
  args = [app_root]+args
  File.expand_path(File.join(args))
end

class Helper
  def self.accept(cmd)
    c = TCPSocket.new('localhost', 9292)
    c.puts cmd.to_s
    return JSON.parse(c.read) rescue nil
  end
  def self.history
    accept :history
  end
  def self.clear
    accept :clear
  end
  def self.exit
    accept :exit
  end
end
class String
  def sort
    self.split('').sort.join('')
  end
  def sort!
    replace(self.sort)
  end
end

RSpec::Matchers.define :have_query_string do |expected|
  match do |value|
    expected.sort == value.sort
  end

  failure_message_for_should do |value|
    "expected #{value.inspect} to match #{expected.inspect}"
  end
end
#======================================#
#=           contain_string           =#
#======================================#
# Check if a string has another string. Usage:
# some_string.should contain("my string")
RSpec::Matchers.define :contain_string do |needle|
  match do |haystack|
    haystack.index(needle) ? true : false
  end
end

class Hash
  def indifferent
    Hash.new { |hash,key| hash[key.to_s] if key.class == Symbol }.merge(self)
  end
end

def write_log(type, content)
  KM.instance_eval { @log_dir = __('log') }
  log_name = KM.send :log_name, type
  File.open(log_name, 'w+') do |fh|
    fh.puts content
  end
end

accept = Accept.new
