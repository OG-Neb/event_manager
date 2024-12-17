require 'csv'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  phone = phone.to_s.gsub(/\D/, '') # Remove non-numeric characters
  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == '1'
    phone[1..10]
  else
    'Bad number'
  end
end

def extract_hour(reg_date)
  DateTime.strptime(reg_date, "%m/%d/%y %H:%M").hour
end

def extract_day_of_week(reg_date)
  DateTime.strptime(reg_date, "%m/%d/%y %H:%M").wday
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hourly_count = Hash.new(0)
days_of_week = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  hour = extract_hour(row[:regdate])
  day = extract_day_of_week(row[:regdate])

  hourly_count[hour] += 1
  days_of_week[day] += 1

  legislators = 'Your legislators here' # Replace this with real logic if needed
  form_letter = erb_template.result(binding)

  # Save the letters
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter }

  puts "#{name} (Phone: #{phone_number}, Registered at Hour: #{hour}, Day: #{day})"
end

puts "\nPeak Registration Hours:"
hourly_count.sort_by { |hour, count| -count }.each do |hour, count|
  puts "Hour #{hour}: #{count} registrations"
end

day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
puts "\nPeak Registration Days:"
days_of_week.sort_by { |day, count| -count }.each do |day, count|
  puts "#{day_names[day]}: #{count} registrations"
end
