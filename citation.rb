require './author'
require './journal_location'
require './note'

# Citation contains EVERYTHING after taxa epithet
class Citation
  @@non_multi_cite = File.read('non_multi_cite.txt').split("\n###---###\n").map{|e| e[0..-2]}
  @@multi_cite = File.read('multi_cite.txt').split("\n###---###\n").map{|e| e[0..-2]}

  attr_reader :raw,
  :authors,
  :journal_location,
  :notes


  def initialize(elements)
    # Dealing with pure text citations
    if elements.class == String
      unless elements == ''
        split = elements.split(" ")
        @date = split.delete_at(-1).to_i
        @authors = split.select{|w| w.match(/\w/)}.map{|a| Author.new(a)}
      end


    # Dealing with HTML citations
    elsif elements.class == Nokogiri::XML::NodeSet
      # binding.pry
      # puts elements.text
      elements = elements.select{|e| e.text.strip != ''}
      start = elements.index{ |e| e.name != 'text' and e.text.strip != ""}
      date_idx = elements.index{ |e| e.text.strip.match(/[1,2][7,8,9,1,0]\d\d/)}
      authors = elements[start..(date_idx-1)].select{|e| e.name == 'a'}

      # @raw = elements

      @authors = authors.map{|a| Author.new(a)}

      journal_idx = date_idx + 1
      location_idx = date_idx + 2
      loc = elements[location_idx].text
      other_date = loc.strip.split(" ")[-1].match(/(?<!")18\d{2}|(?<!")20\d{2}|(?<!")17\d{2}|(?<!")19\d{2}/)
      if other_date
        entry = elements[date_idx..-1].map{ |e| e.text}.join("")

        if @@multi_cite.include?(entry)
          @journal_location = multi_parse(elements, loc, location_idx, journal_idx, date_idx)
        elsif @@non_multi_cite.include?(entry)
          @journal_location = JournalLocation.new(elements[date_idx..location_idx])
        else
          puts entry
          puts "Multiple Journals? y or n"
          binding.pry
          ans = gets

          if ans.chomp.upcase == "Y"
            File.open("multi_cite.txt", "a+") do |f|
              f.puts(entry)
              f.puts("\n###---###\n")
            end
            @journal_location = multi_parse(elements, loc, location_idx, journal_idx, date_idx)
            # binding.pry

            # @date = [elements[date_idx].text.match(/[1,2][7,8,9,1,0]\d\d/).to_s.to_i]
            # @journal = [Journal.new(elements[journal_idx])]
            # @description_location = [loc.strip.split(" ")[0..-2].join(" ")]
            # @date << loc.strip.split(" ")[-1].to_i
            # @journal << Journal.new(elements[location_idx+1])
            # @description_location << elements[location_idx+2].text
            location_idx = location_idx + 2
          else
            File.open("non_multi_cite.txt", "a+") do |f|
              f.puts(entry)
              f.puts("\n###---###\n")
            end
          end
        end
      end

      @journal_location ||= JournalLocation.new(elements[date_idx..location_idx])
      # @date = elements[date_idx].text.match(/[1,2][7,8,9,1,0]\d\d/).to_s.to_i
      # @journal = Journal.new(elements[journal_idx])
      # # if @journal.name == "BirdsAm."
      # #   binding.pry
      # # end
      # if elements[location_idx].name != 'text'
      #   puts "NON TEXT LOCATION #{@raw.text}"
      # end
      # @description_location = elements[location_idx].text

      @notes = []
      elements[(location_idx+1)..-1].each do |note|
        # Check first note for date, if date, add another citation.
        # binding.pry
        if note.text.strip != ""
          @notes << Note.new(note)
        end
      end
      # binding.pry

      ### MAKE INTO JOURNAL CLASS / Location
      # @journal = elements[start + 2].text
      # @journal_link = elements[start + 2].children[0].attributes['href'].value
      # @journal_location = elements[start + 3].text.strip

      ###
    end
    # binding.prypar

    # @author = e.children[3]
    # @year = e.children.find { |c| c.text[0..1] == " 1" || c.text[0..1] == " 2"}.text.to_i
    #
    # citon_start = e.children.index(@year)+1
    #
    # links = e.children[citon_start..-1].select{ |c| c[:href] != nil || c.children.any?{ |cc| cc[:href] != nil}}
    # citon_end = links.length >1 ? e.children.index(links[1]) -1 : -1
    #
    # @citation = Citation.new(e.children[citon_start..citon_end])
    #
    # @notes = e.children[(citon_end+1)..-1].map{ |n| Note.new(n)}.select{|n| n.filled}
  end

  def multi_parse(elements, loc, location_idx, journal_idx, date_idx)
    loc_node = elements[location_idx]
    loc_node.content = loc.strip.split(" ")[0..-2].join(" ")
    # binding.pry
    first = [elements[date_idx], elements[journal_idx], loc_node]
    # date_node = Nokogiri::XML::Text.new(loc.strip.split(" ")[-1], loc_node.document)
    second = [loc.strip.split(" ")[-1], elements[location_idx+1], elements[location_idx+2]]
    multi = [JournalLocation.new(first), JournalLocation.new(second)]
    # binding.pry
    multi
  end
end
