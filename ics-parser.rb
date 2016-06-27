#!/usr/bin/ruby

require 'bundler'
Bundler.setup

require 'icalendar'
require 'open-uri'
require 'yaml'
require 'slop'
require 'word_wrap'

opts = Slop.parse!(help: true, ignore_case: true) do
  banner "Usage: #{__FILE__} [options] <ics file>"
end

if ARGV.first
  ics = open(ARGV.first).read
  cal = Icalendar.parse(ics).first
else
  puts "Error: .ics file must be specified.\n\n"
  puts opts
  exit false
end

events = []

cal.events.each do |event|
  event_item = {
    "title" => event.summary.strip,
    "speaker" => nil,
    "start" => event.dtstart.strftime('%F %R %Z'),
    "end" => event.dtend.strftime('%F %R %Z'),
    "description" => event.description.strip.wrap(72)
  }
  events.push event_item
end

conf_title = cal.x_wr_calname.first

conference = {
  "title" => conf_title.strip,
  "description" => nil,
  "location" => nil,
  "events" => events
}

puts conference.to_yaml(separator: nil, block: true, fold: true).gsub(/^(\s*- [\s\w]+:)/, "\n\\1").gsub(/^---$/, '').gsub(/: \|-/, ': |').strip
