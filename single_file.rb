require './noko'
require 'pry'

file = 'stru.html'
d = Nokogiri::HTML.parse(open("./pages/2019/10/1/avtax/#{file}"))
p = parse_document(d, file, true)
err = p.select{|e| e.class == Hash}
err_types = err.map{|e| e.keys.first}
binding.pry
