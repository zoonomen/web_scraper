require 'nokogiri'
require 'pry'
class Author
  attr_reader :name, :link, :note

  def initialize(info)
    # binding.pry
    if info.class == String
      @name = info.strip.gsub(/\s/, " ").strip.gsub(/[ ]+/, " ")
    else
      @name = info.text.strip.gsub(/\s/, " ").strip.gsub(/[ ]+/, " ")
      @link = info.attributes['href'].value.strip.gsub(/\s/, " ").strip.gsub(/[ ]+/, " ")
      base = 'http://www.zoonomen.net/'
      suffix = @link.split("/")[1..-1].join("/")
      anchor_name = @link.split("#")[-1]
      # binding.pry
      # ad = Nokogiri::HTML.parse(open(base+suffix))
      #
      # anchor = ad.css('a').find do |e|
      #   e.attributes['name'] != nil and e.attributes['name'].value == anchor_name
      # end
      # notes = []
      # node = anchor.next
      # while node and node.name != 'hr'
      #   notes << node
      #   node = node.next
      # end
      #
      # @note = notes
      #
      # unless @name
      #   binding.pry
      # end

    end
  end
end
