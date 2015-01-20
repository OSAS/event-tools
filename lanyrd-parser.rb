#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri/cached'
require 'yaml'
require 'slop'
require 'geocoder'
require 'nearest_time_zone'
require 'tzinfo'
require 'word_wrap'


### Handle command-line options

opts = Slop.parse!(help: true, ignore_case: true) do
  on 'l', 'location', "Conference location (also attempts auto-timezone lookup)", argument: :optional
  on 't', 'timezone', "Time Zone", argument: :optional, default: "GMT"
  on 'y', 'year', "Year", argument: :optional, default: Time.now.year
end


### Load info from Lanyrd

if ARGV
  url = "http://lanyrd.com/#{opts[:year]}/#{ARGV.first}/"
  intro = Nokogiri::HTML(open(url).read.gsub(/\n/, ' ').squeeze(' '))
  schedule = Nokogiri::HTML(open("#{url}schedule/").read.gsub(/\n/, ' ').squeeze(' '))
else
  exit false
end


### Intro page

summary = intro.css('#event-description')
summary = summary.text.split(' (hide)').first.strip unless summary.text.empty?

tagline = intro.css('.tagline')/
tagline = tagline.text if tagline


### Schedule page

# Location

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
  begin
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
      "description" => item.css('.desc').text.strip.wrap(72)
    }
    events.push event
  rescue
  end
end


### Put it all together

conference = {
  "name" => schedule.css('.content h1').first.text.strip.gsub(/schedule$/, ''),
  "location" => location,
  "timezone" => timezone,
  "description" => (summary.to_s || tagline.to_s || '').strip.wrap(72),
  "talks" => events
}

puts conference.to_yaml(separator: nil, block: true, fold: true).gsub(/^(\s*- [\s\w]+:)/, "\n\\1").gsub(/^---$/, '').gsub(/: \|-/, ': |').strip
