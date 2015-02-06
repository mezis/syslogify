# Syslogify

Redirects standard output and standard error to syslog.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'syslogify'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install syslogify

## Usage

As soon as the gem is loaded, output will be diverted if:

- `STDOUT` is an interactive terminal; or
- the environment is `development` or `test`; and
- the environment varible `FORCE_SYSLOG` is unset.

The current environment is determined by looking at, by order of decreasing
precedence, the `AR_ENV` environment variable, `Rails.env` if available, and the
`RACK_ENV` environment variable. It defaults to `development`.

If you wish to delay diversion, change your Gemfile to:

```ruby
gem 'syslogify', require: false
```

and start and stop diversion at your convenience:

```ruby
require 'syslogify/forker'

Syslogify::Forker.instance.start
# do stuff
Syslogify::Forker.instance.stop
```

## Contributing

1. Fork it ( https://github.com/mezis/syslogify/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
