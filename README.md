# Foxtracker

[![Gem Version](https://badge.fury.io/rb/foxtracker.svg)](https://badge.fury.io/rb/foxtracker)

Foxtracker is a parser for tracker music formats.  Right now it only supports XM
(FastTracker II) modules.  Support for more formats is to be done.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'foxtracker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install foxtracker

## Usage

```ruby
require "foxtracker/parser"

xm = Foxtracker::Parser.read(
  # path to xm file:
  File.expand_path("./siuperdu[perxmldsosnmg v2.xm", __dir__),
  # display debug output during parsing (default false)
  debug: true
)
#=> #<Foxtracker::Format::ExtendedModule title="superdupersongxmldng" tracker="MilkyTracker 1.00.00" ...>

xm
  .patterns.first # the pattern 0
  .channels.first # the first channel
  .first          # the first row/note for the channel
  .note           #=> 85 (C-7); the note value

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/foxtracker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Foxtracker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/foxtracker/blob/master/CODE_OF_CONDUCT.md).
