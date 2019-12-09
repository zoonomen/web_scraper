require 'date'
require 'pry'
require './noko'
################
# Flag for files parsed today
#########
todays_files = true

year = 2019
month = 9
day = 29

##############
if todays_files
  today = DateTime.now
  year = today.year
  month = today.month
  day = today.day
end

path_base = "./pages/#{year}/#{month}/#{day}/"

files = File.read('rescues.txt').split


err_info = []
err_info << "NOTE all data is shown after a '-'\nif nothing comes after a '-' means there is a blank line\n\n"

files.each do |f|
  next if f == 'pass.html'
  
  path = path_base + f
  d = Nokogiri::HTML.parse(open(path))
  p = parse_document(d, f, true)
  err = p.select{|e| e.class == Error}

  err.each do |e|
    err_info << e.to_s
  end
end

File.open("error_report.txt", "w+") do |f|
  err_info.each{|e| f.puts(e)}
end
