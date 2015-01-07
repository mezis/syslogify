require 'syslogify/version'
require 'singleton'
require 'syslog'

module Syslogify
  # Spawns a logger process that takes your stdout and stderr to syslog,
  # by reopening them and piping to the subprocess.
  #
  # Note that the process ID reported in syslog will be that of the logger
  # subprocess.
  #
  class Forker
    include Singleton

    def initialize
      @pid = nil
    end

    def start
      return if @pid
      
      rd, wr = IO.pipe
      @old_stdout = STDOUT.dup
      @old_stderr = STDERR.dup

      Syslog.open(_identity, Syslog::LOG_CONS | Syslog::LOG_NDELAY)
      Syslog.log(Syslog::LOG_NOTICE, 'Diverting logs to syslog')

      @pid = fork do
        STDIN.reopen(rd)
        wr.close
        Process.daemon # otherwise we'll intercept signals

        while line = STDIN.gets
          Syslog.log(Syslog::LOG_NOTICE, line.gsub('%', '%%'))
        end
        Syslog.log(Syslog::LOG_NOTICE, 'Shutting down')
      end

      Syslog.close
      Process.detach(pid) # the subprocess will shut down on its own once starved of input

      rd.close
      STDOUT.reopen(wr)
      STDERR.reopen(wr)
      STDOUT.sync = STDERR.sync = true
     
      begin
        @old_stderr.puts('Check syslog for further messages')
      rescue Errno::EPIPE
        # this can happen if something else tampered with our @old streams, 
        # e.g. the daemons library
      end
      self
    end

    def stop
      return unless @pid
      # NOTE: we shouldn't kill the subprocess (which can be shared igqf the parent
      # forked after #start), and it'll shut down on its own anyways.
      STDOUT.reopen(@old_stdout) unless @old_stdout.closed?
      STDERR.reopen(@old_stderr) unless @old_stderr.closed?
      @old_stdout = @old_stderr = nil

      @pid = nil
      self
    end

    # useful when e.g. the process name changes, and/or after forking
    def restart
      stop
      start
    end

    private

    def _identity
      ENV.fetch('SYSLOG_IDENTITY', File.basename($PROGRAM_NAME))
    end
  end
end
