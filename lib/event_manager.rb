require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(number)
  number.to_s.gsub!(/\D/, '')
  return number[1..-1] if number.length == 11 && number[0] == '1'
  number
end

def valid_number?(number)
  number.length == 10 ? true : false
end

def parse_date(date_time, date_hash)
  date = date_time.split(' ')[0].split('/')
  year = "20#{date[2]}".to_i
  month = date[0].to_i
  day = date[1].to_i
  date_obj = Date.new(year, month, day)
  date_hash[date_obj.wday] = 0 unless date_hash.key?(date_obj.wday)
  date_hash[date_obj.wday] += 1
end

def parse_time(date_time, hour_hash)
  hour = date_time.split(' ')[1].split(':')[0]
  hour_hash[hour] = 0 unless hour_hash.key?(hour)
  hour_hash[hour] += 1
end

def get_most_common(hash)
  hash.sort_by {|k,v| v}.reverse
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour = Hash.new
date = Hash.new
WEEKDAYS = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)


contents.each do |row|
  id = row[0]
  name = row[:first_name]
  # Clean and validate phone numbers
  phone = clean_phone_number(row[:homephone])
  valid = valid_number?(phone)
  puts "#{phone} - #{valid}"
  parse_time(row[:regdate], hour)
  parse_date(row[:regdate], date)
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

get_most_common(hour).each { |k,v| puts "#{k} - #{v}"}
get_most_common(date).each { |k,v| puts "#{WEEKDAYS[k - 1]} - #{v}"}