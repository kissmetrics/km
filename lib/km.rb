require 'cgi'
require 'socket'
require 'fileutils'
require 'km/saas'

class Hash
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end if !respond_to?(:reverse_merge)
  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end if !respond_to?(:reverse_merge)
end

class KMError < StandardError; end

class KM
  @id        = nil
  @key       = nil
  @logs      = {}
  @host      = 'trk.kissmetrics.com:80'
  @log_dir   = '/tmp'
  @to_stderr = true
  @use_cron  = false

  class << self
    class IdentError < StandardError; end
    class InitError < StandardError; end

    def init(key, options={})
      default = {
        :host      => @host,
        :log_dir   => @log_dir,
        :to_stderr => @to_stderr,
        :use_cron  => @use_cron
      }
      options.reverse_merge!(default)
      begin
        @key       = key
        @host      = options[:host]
        @log_dir   = options[:log_dir]
        @use_cron  = options[:use_cron]
        @to_stderr = options[:to_stderr]
        log_dir_writable?
      rescue Exception => e
        log_error(e)
      end
    end

    def identify(id)
      @id = id
    end

    def record(action,props={})
      props = hash_keys_to_str(props)
      begin
        return unless is_initialized_and_identified?
        return set(action) if action.class == Hash

        props.update('_n' => action)
        generate_query('e', props)
      rescue Exception => e
        log_error(e)
      end
    end

    def alias(name, alias_to)
      begin
        return unless is_initialized?
        generate_query('a', { '_n' => alias_to, '_p' => name }, false)
      rescue Exception => e
        log_error(e)
      end
    end

    def set(data)
      begin
        return unless is_initialized_and_identified?
        generate_query('s', data)
      rescue Exception => e
        log_error(e)
      end
    end

    def send_logged_queries
      line = nil
      begin
        return unless File.exists?(log_name(:query))
        FileUtils.move(log_name(:query), log_name(:send))
        File.open(log_name(:send)) do |fh|
          while not fh.eof?
            begin
              line = fh.readline.chomp
              send_query(line)
            rescue Exception => e
              log_query(line) if line
              log_error(e)
            end
          end
        end
        FileUtils.rm(log_name(:send))
      rescue Exception => e
        log_error(e)
      end
    end

    def log_dir
      @log_dir
    end
    def host
      @host
    end

    protected
    def hash_keys_to_str(hash)
      Hash[*hash.map { |k,v| k.class == Symbol ? [k.to_s,v] : [k,v] }.flatten] # convert all keys to strings
    end
    def reset
      @id        = nil
      @key       = nil
      @logs      = {}
      @host      = 'trk.kissmetrics.com:80'
      @log_dir   = '/tmp'
      @to_stderr = true
      @use_cron  = false
    end

    def log_name(type)
      return @logs[type] if @logs[type]
      fname = ''
      env = ''
      # env = '_' + Rails.env if defined? Rails
      case type
      when :error
        fname = "kissmetrics#{env}_error.log"
      when :query
        fname = "kissmetrics#{env}_query.log"
      when :sent
        fname = "kissmetrics#{env}_sent.log"
      when :send
        fname = Time.now.to_i.to_s + "kissmetrics_#{env}_sending.log"
      end
      @logs[type] = File.join(@log_dir,fname)
    end

    def log_query(msg)
      log(:query,msg)
    end

    def log_sent(msg)
      log(:sent,msg)
    end

    def log_send(msg)
      log(:send,msg)
    end

    def log_error(error)
      if defined?(HoptoadNotifier)
        HoptoadNotifier.notify_or_ignore(KMError.new(error))
      end
      msg = Time.now.strftime("<%c> ") + error.message
      $stderr.puts msg if @to_stderr
      log(:error, msg)
    end

    def log(type,msg)
      begin
        File.open(log_name(type), 'a') do |fh|
          fh.puts(msg)
        end
      rescue Exception => e
        raise KMError.new(e) if type.to_s == 'query'
        # just discard at this point otherwise
      end
    end


    def generate_query(type, data, update=true)
      data = hash_keys_to_str(data)
      query_arr = []
      query     = ''
      data.update('_p' => @id) unless update == false
      data.update('_k' => @key)
      data.update '_d' => 1 if data['_t']
      data.reverse_merge!('_t' => Time.now.to_i)
      data.inject(query) do |query,key_val|
        query_arr <<  key_val.collect { |i| CGI.escape i.to_s }.join('=')
      end
      query = '/' + type + '?' + query_arr.join('&')
      if @use_cron
        log_query(query)
      else
        begin
          send_query(query)
        rescue Exception => e
          log_query(query)
          log_error(e)
        end
      end
    end

    def send_query(line)
      if defined? Rails and not Rails.env.production?
        log_sent(line)
        return
      end
      host,port = @host.split(':')
      begin
        sock = TCPSocket.open(host,port)
        request = 'GET ' +  line + " HTTP/1.1\r\n"
        request += "Host: " + Socket.gethostname + "\r\n"
        request += "Connection: Close\r\n\r\n";
        sock.print(request)
        sock.close
      rescue Exception => e
        raise KMError.new("#{e} for host #{@host}")
      end
      log_sent(line)
    end

    def log_dir_writable?
      if not FileTest.writable? @log_dir
        $stderr.puts("Could't open #{log_name(:query)} for writing. Does #{@log_dir} exist? Permissions?") if @to_stderr
      end
    end

    def is_identified?
      if @id == nil
        log_error IdentError.new("Need to identify first (KM::identify <user>)")
        return false
      end
      return true
    end

    def is_initialized_and_identified?
      return false unless is_initialized?
      return is_identified?
    end

    def is_initialized?
      if @key == nil
        log_error InitError.new("Need to initialize first (KM::init <your_key>)")
        return false
      end
      return true
    end
  end
end

if __FILE__ == $0
  $stderr.puts "At least one argument required. #{$0} <km_key> [<log_dir>]" unless ARGV[0]
  KM.init(ARGV[0], :log_dir => ARGV[1] || KM.log_dir, :host => ARGV[2] || KM.host)
  KM.send_logged_queries
end
