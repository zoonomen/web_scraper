require './journal'
class JournalLocation
  attr_reader :date, :location, :journal

  def initialize(elements)
    date_idx, journal_idx, location_idx = (0..2).to_a
    # binding.pry
    if elements[date_idx].class == String
      @date = elements[date_idx].to_i
    else
      d = elements[date_idx]
      date_int = d.text.match(/18\d{2}|20\d{2}|17\d{2}|19\d{2}/).to_s.to_i
      if d.name == 'text'
        @date = date_int
      else
        @date = {date_int => d.attributes['href'].value}
      end
    end

    @journal = Journal.new(elements[journal_idx])
    # if @journal.name == "BirdsAm."
    #   binding.pry
    # end
    if elements[location_idx].name != 'text'
      # binding.pry
      # puts "NON TEXT LOCATION #{@raw}"
    end

    if elements[location_idx].name == 'text'
      @location = elements[location_idx].text
    else
      l = elements[location_idx]
      @location = {l.text => l.attributes['href'].value}
    end
  end

end
