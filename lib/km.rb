require 'uri'
require 'socket'
require 'net/http'
require 'fileutils'
require 'km/saas'

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
        :use_cron  => @use_cron,
        :env       => set_env,
      }
      options = default.merge(options)

      begin
        @key       = key
        @host      = options[:host]
        @log_dir   = options[:log_dir]
        @use_cron  = options[:use_cron]
        @to_stderr = options[:to_stderr]
        @env       = options[:env]
        log_dir_writable?
      rescue Exception => e
        log_error(e)
      end
    end

    def set_env
      @env = Rails.env if defined? Rails
      @env ||= ENV['RACK_ENV']
      @env ||= 'production'
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

    def send_logged_queries # :nodoc:
      line = nil
      begin
        query_log = log_name(:query_old)
        query_log = log_name(:query) unless File.exists?(query_log)
        return unless File.exists?(query_log) # can't find logfile to send
        FileUtils.move(query_log, log_name(:send))
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

    # :stopdoc:
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
      env = @env ? "_#{@env}" : ''
      case type
      when :error
        fname = "kissmetrics#{env}_error.log"
      when :query
        fname = "kissmetrics#{env}_query.log"
      when :query_old # backwards compatibility
        fname = "kissmetrics_query.log"
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
      rescue Exception # rescue incase hoptoad has issues
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
      data['_t'] ||= Time.now.to_i

      data.inject(query) do |query,key_val|
        query_arr <<  key_val.collect { |i| URI.escape i.to_s }.join('=')
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
      if @env != 'production'
        log_sent(line)
        return
      end
      begin
        host,port = @host.split(':')
        proxy = URI.parse(ENV['http_proxy'] || ENV['HTTP_PROXY'] || '')
        res = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).start(host, port) do |http|
          http.get(line)
        end
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
    # :startdoc:
  end
end
