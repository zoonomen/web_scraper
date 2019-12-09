require 'fileutils'
require 'date'
require 'pry'
# require 'file'

r = File.read('./pages/2019/10/2/cit/jours.html')

enc = r.encode('UTF-8', 'ISO-8859-1')
binding.pry
