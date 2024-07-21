require 'csv'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  phone = row[:homephone].to_s.gsub(/\D/, '')
  if phone.length == 11 && phone[0] == '1'
    puts "#{phone[1..-1]} - Good"
  elsif phone.length == 10
    puts "#{phone} - Good"
  else 
    puts "#{phone} - Bad"
  end
end