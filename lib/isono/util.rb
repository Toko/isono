# -*- coding: utf-8 -*-

require 'digest/sha1'
require 'hmac-sha1'
require 'thread'
require 'stringio'

require 'shellwords'
unless Shellwords.respond_to? :shellescape
  require 'ext/shellwords'
end

module Isono
  module Util
    
    ##
    # Convert to snake case.
    #
    #   "FooBar".snake_case           #=> "foo_bar"
    #   "HeadlineCNNNews".snake_case  #=> "headline_cnn_news"
    #   "CNN".snake_case              #=> "cnn"
    #
    # @return [String] Receiver converted to snake case.
    #
    # @api public
    def snake_case(str)
      return str.downcase if str.match(/\A[A-Z]+\z/)
      str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z])([A-Z])/, '\1_\2').
        downcase
    end
    module_function :snake_case
    
    def gen_id(str=nil)
      Digest::SHA1.hexdigest( (str.nil? ? rand.to_s : str) )
    end
    module_function :gen_id


    def quote_args(cmd_str, args=[], quote_char='\'')
      quote_helper =
        if quote_char
          proc { |a|
            [quote_char, Shellwords.shellescape(a), quote_char].join
          }
        else
          proc { |a|
            Shellwords.shellescape(a)
          }
        end
      sprintf(cmd_str, *args.map {|a| quote_helper.call(a) })
    end
    module_function :quote_args

    # system('/bin/ls')
    # second arg gives 
    # system('/bin/ls %s', ['/home'])
    def system(cmd_str, args=[], opts={})
      unless EventMachine.reactor_running?
        raise "has to prepare EventMachine context"
      end

      cmd = quote_args(cmd_str, args, (opts[:quote_char] || '\''))

      capture_io = opts[:io] || StringIO.new
      stdin_buf = opts[:stdin_input]
      
      evmsg = {:cmd => cmd}
      wait_q = ::Queue.new
      if opts[:timeout] && opts[:timeout].to_f > 0.0
        EventMachine.add_timer(opts[:timeout].to_f) {
          wait_q.enq(RuntimeError.new("timeout child process wait: #{opts[:timeout].to_f} sec(s)"))
        }
        evmsg[:timeout] = opts[:timeout].to_f        
      end
      popenobj = EventMachine.popen(cmd, EmSystemCb, capture_io, stdin_buf, proc { |exit_stat|
                                      wait_q.enq(exit_stat)
                                    })
      pid = EventMachine.get_subprocess_pid(popenobj.signature)
      evmsg[:pid] = pid
      if self.respond_to? :logger
        logger.debug("Exec command (pid=#{pid}): #{cmd}")
      end

      stat = wait_q.deq
      evmsg = {}
      
      case stat
      when Process::Status
        evmsg[:exit_code] = stat.exitstatus
        if stat.exited? && stat.exitstatus == 0
        else
          raise "Unexpected status from child: #{stat}"
        end
      when Exception
        raise stat
      else
        raise "Unknown signal from child: #{stat}"
      end
      
    end
    module_function :system

    class EmSystemCb < EventMachine::Connection
      def initialize(io, in_buf, exit_cb)
        @io = io
        @in_buf = in_buf
        @exit_cb = exit_cb
      end

      def post_init
        # send data to stdin for child process
        if @in_buf
          send_data @in_buf
        end
      end
      
      def receive_data data
        @io.write(data)
      end
      
      def unbind()
        @exit_cb.call(get_status)
      end
    end

    # return ruby binary path which is expected to be used in
    # the current environment.
    def ruby_bin_path
      #config_section.ruby_bin_path || ENV['_'] =~ /ruby/ ||
      require 'rbconfig'
      File.expand_path(Config::CONFIG['RUBY_INSTALL_NAME'], Config::CONFIG['bindir'])
    end
    module_function :ruby_bin_path

  end
end

