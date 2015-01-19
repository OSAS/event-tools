#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'slop'
require 'geocoder'
require 'nearest_time_zone'
require 'tzinfo'
require 'word_wrap'


### Handle command-line options

opts = Slop.parse(help: true, ignore_case: true) do |o|
  o.string '-l', '--location', "Conference location (also attempts auto-timezone lookup)"
  o.string '-t', '--timezone', "Time Zone", default: "GMT"
  o.integer '-y', '--year', "Year", default: Time.now.year
  o.on '-h', '--help' do
    puts o
    exit
  end
end


### Intro page

intro = Nokogiri::HTML(open('infra-intro.html').read.gsub(/\n/, ' ').squeeze(' '))

summary = intro.css('#event-description')
summary = summary.text.split(' (hide)').first.strip if summary

tagline = intro.css('.tagline')/
tagline = tagline.text if tagline


### Schedule page

# Location

schedule = Nokogiri::HTML(open('infra.html').read.gsub(/\n/, ' ').squeeze(' '))

place = schedule.css('.location a')

location = if opts[:location]
             opts[:location]
           elsif place
             "#{place[2].text.strip}, #{place[1].text.strip}"
           else
             ''
           end

if location
  Geocoder.configure(lookup: :nominatim)
  geo = Geocoder.search(location).first.data
  timezone = NearestTimeZone.to(geo['lat'].to_i, geo['lon'].to_i)
end


# Events

events = []

schedule.css('.schedule-item').each do |item|
  # Grab start and end times
  dtstart = item.css('.dtstart .value-title').attr('title').to_s.split('+').first.tr('T', ' ')
  dtend = item.css('.dtend .value-title').attr('title').to_s.split('+').first.tr('T', ' ')

  # Shorten timezone to abbreviation (w/ DST-awareness)
  tz = TZInfo::Timezone.get(timezone).period_for_local(Time.parse(dtstart)).zone_identifier.to_s

  # Form & add individual event
  event = {
    "title" => item.css('h2 a').text.strip,
    "speaker" => item.css('.session-speakers a').text.strip,
    "start" => Time.parse(dtstart).strftime('%F %R') + " #{tz}",
    "end" => Time.parse(dtend).strftime('%F %R') + " #{tz}",
    #"end" => item.css('.dtend .value-title').attr('title'),
    "description" => item.css('.desc').text.wrap(72)#.gsub(/\n/, ''),
  }
  events.push event
end


### Put it all together

conference = {
  "title" => schedule.css('.content h1').first.text.strip.gsub(/schedule$/, ''),
  "location" => location,
  "timezone" => timezone,
  "summary" => (summary || tagline || '').wrap(72),
  "events" => events
}

puts conference.to_yaml(separator: nil, block: true, fold: true).gsub(/^(\s*- [\s\w]+:)/, "\n\\1").gsub(/^---$/, '').gsub(/: \|-/, ': |').strip
