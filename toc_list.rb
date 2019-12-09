require 'nokogiri'
require 'pry'
require './noko'
require 'date'
require 'open-uri'
require 'fileutils'
require './parser_helpers'
require './downloader'
require './data_store'

################
download_new_toc = true
force_download = false
new_multi_citon = false
start_group = 'STRUTHIONIFORMES'
end_group = 'Thraupidae'
################

downloader = Downloader.new
downloader.new_toc if download_new_toc
reset_multi_citons if new_multi_citon

page_links = find_page_links(start_group, end_group)

parsed_list = {}
# rescues = []
err_info = []
err_info << "NOTE all data is shown after a '-'\nif nothing comes after a '-' means there is a blank line\n\n"
ds = DataStore.new
page_links.each_with_index do |pl, idx|
  next if pl.path == 'pass.html'
  puts "--------------\n#{idx}\n#{pl.path}\n--------------"

  data = downloader.taxa_data(pl.path, force_download)
  d = Nokogiri::HTML.parse(data)

  ds.add_document(d, pl.path)
  parsed = parse_document(d, pl.path, true)
  errors = parsed.select{|e| e.class == Error}

  if errors.count == 0
    parsed_list[idx] = [pl.name, parsed]
  else
    # rescues << pl.path
    errors.each do |e|
      err_info << e.to_s
    end
  end
end

# File.open("rescues.txt", "w+") do |f|
#   rescues.each{|e| f.puts(e)}
# end

File.open("error_report.txt", "w+") do |f|
  err_info.each{|e| f.puts(e)}
end

# build_note_report(parsed_list)
# build_author_report(parsed_list)
# build_journal_report(parsed_list)

binding.pry

# today = DateTime.now
# path_base = "./pages/#{today.year}/#{today.month}/#{today.day}/avtax/"
# FileUtils.mkdir_p( path_base )

#
# file_path = path_base + pl.path
# if force_download_new_data || !File.exist?(file_path)
#
#   puts "Downloading #{pl.path}"
#   open(file_path, 'wb') do |file|
#     open(("http://www.zoonomen.net/avtax/"+ pl.path)) do |page|
#       file.write(page.read)
#     end
#   end
# end

# begin
#   parsed = parse_document(d, pl[1], false)
#   parsed_list[idx] = [pl[0], parsed]
# rescue
#   puts "RESCUED #{pl[1]}"
#   rescues << pl[1]
#   unless file_path == 'pass.html'
#     p = parse_document(d, pl[1], true)
#     err = p.select{|e| e.class == Error}
#
#     err.each do |e|
#       err_info << e.to_s
#     end
#   end
#
# end
