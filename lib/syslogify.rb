require 'syslogify/forker'

begin
  environment = ENV['AR_ENV'] || (defined?(Rails) && Rails.env) || ENV['RACK_ENV'] || 'development'
  if (STDOUT.tty? || environment =~ /development|test/) && !ENV['FORCE_SYSLOG']
    $stderr.puts "syslogify not auto-starting (#{environment})"
  else
    $stderr.puts "syslogify auto-starting (#{environment})"
    Syslogify::Forker.instance.start
  end
end

