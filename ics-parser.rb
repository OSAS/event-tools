#!/usr/bin/ruby

require 'icalendar'
require 'open-uri'
require 'yaml'

ics = open('infra-at-scale-schedule.ics').read

cal = Icalendar.parse(ics).first

#puts ics.to_yaml
#puts cal.x_wr_calname
#puts cal.instance_variables
#p cal.public_methods
#puts cal.timezone.to_s

events = []

cal.events.take(1).each do |event|
  #p event.instance_variables
  #p event.public_methods
  #puts event.to_yaml
  #puts event.summary
  #puts event.description
  #puts event.dtstart
  #puts event.dtend
  #puts event.url

  event_item = {
    "title" => event.summary.strip,
    "speaker" => "",
    "start" => event.dtstart.strftime('%F %R'),
    "end" => event.dtend.strftime('%F %R'),
    "description" => event.description.strip
  }
  events.push event_item
end

conf_title = cal.x_wr_calname.first

conference = {
  "title" => conf_title.strip,
  "description" => "",
  "events" => events
}

puts conference.to_yaml
