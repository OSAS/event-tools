# event-tools

Contained in this repository are a few utilities that make it easier to work
with rh-event-style YAML-based events.

Currently, the following are included:

* lanyrd-parser.rb: for parsing Lanyrd events and displaying a mostly-usable
  YAML representation (which should probably be mildly edited before
  submitting to )
* ics-parser.rb: .ics importer (work-in-progress)

## Usage

To use these commands, ensure you have Ruby and bundler installed
(`yum install rubygem-bundler ruby-devel`) then run `bundle install`


### Lanyrd parser

```
Usage: ./lanyrd-parser.rb [options] <conference>
    -l, --location      Conference location (also attempts auto-timezone lookup)
    -y, --year          Year (default: 2015)
    -h, --help          Display this help message.
```

You must specify the conference short name (slug). This is found in Lanyrd
URLs, directly after the year.

The parser currently outputs to `STDOUT` which means you need to redirect to it a file, like so:

```bash
./lanyrd-parser.rb fosdem -y 2014 > fosdem.yml
```

The year is optional and will default to the current year. Locations are parsed
from the Lanyrd metadata and timezones are looked up and specified based on the
location. You may override the location in case they're not specified or are
inaccurate.
