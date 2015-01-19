#!/usr/bin/ruby

require 'icalendar'
require 'open-uri'
require 'yaml'
require 'word_wrap'

ics = open('infra-at-scale-schedule.ics').read

cal = Icalendar.parse(ics).first

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
