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

        while line = STDIN.gets
          Syslog.log(Syslog::LOG_NOTICE, line)
        end
        Syslog.log(Syslog::LOG_NOTICE, 'Shutting down')
      end

      Syslog.close

      rd.close
      STDOUT.reopen(wr)
      STDERR.reopen(wr)
      STDOUT.sync = STDERR.sync = true
      
      @old_stderr.puts('Check syslog for further messages')
      self
    end

    def stop
      return unless @pid
      STDOUT.reopen(@old_stdout)
      STDERR.reopen(@old_stderr)
      @old_stdout = @old_stderr = nil

      Process.kill('TERM', @pid)
      Process.wait(@pid)
      @pid = nil
      self
    end

    private

    def _identity
      @identity ||= ENV.fetch('SYSLOG_IDENTITY', File.basename($PROGRAM_NAME))
    end
  end
end
