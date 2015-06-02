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

    # causes standard output and error to be redirected to syslog
    # (through a subprocess)
    def start
      return if @sink
      
      drain, @sink = IO.pipe
      @old_stdout = STDOUT.dup
      @old_stderr = STDERR.dup

      # Test connection to syslog in the parent process
      Syslog.open(_identity, Syslog::LOG_CONS | Syslog::LOG_NDELAY)
      Syslog.log(Syslog::LOG_NOTICE, 'Diverting logs to syslog')

      # spawn a subprocess which pipes from its standard input to syslog
      pid = fork do
        Process.daemon # otherwise we'll intercept signals
        $PROGRAM_NAME = "#{Syslog.ident}.syslogify"
        STDIN.reopen(drain)
        @sink.close

        while line = STDIN.gets
          Syslog.log(Syslog::LOG_NOTICE, line.force_encoding('binary').gsub('%', '%%'))
        end
        Syslog.log(Syslog::LOG_NOTICE, 'Shutting down')
      end

      Process.detach(pid) # the subprocess will shut down on its own once starved of input
      Syslog.close # the parent does not need syslog access

      # redirect stdout/err to the subprocess
      drain.close
      STDOUT.reopen(@sink)
      STDERR.reopen(@sink)
      STDOUT.sync = STDERR.sync = true
     
      begin
        @old_stderr.puts('Check syslog for further messages')
      rescue Errno::EPIPE
        # this can happen if something else tampered with our @old streams, 
        # e.g. the daemons library
      end
      self
    end

    # cancels the outout redirection
    def stop
      return unless @sink
      # NOTE: we shouldn't kill the subprocess (which can be shared igqf the parent
      # forked after #start), and it'll shut down on its own anyways.
      STDOUT.reopen(@old_stdout) unless @old_stdout.closed?
      STDERR.reopen(@old_stderr) unless @old_stderr.closed?
      @sink.close unless @sink.closed?
      @old_stdout = @old_stderr = nil
      @sink = nil
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
