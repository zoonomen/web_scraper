class Note
  attr_reader :name, :link
  def initialize(info)
    @name = info.text.gsub(/\s/, " ").strip.gsub(/[ ]+/, " ")

    begin
      @link = info.attributes['href'].value
    rescue
      @link = nil
    end
    # binding.pry
  end
end
