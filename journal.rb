class Journal
  attr_reader :name, :link

  def initialize(info)
    unless info.name == 'a'
      info = info.children.find{|c| c.name == 'a'}
    end

    @name = info.text.strip.gsub(/\s/, " ").strip.gsub(/[ ]+/, " ")
    @link = info.attributes['href'].value.strip.gsub(/\s/, " ").strip.gsub(/[ ]+/, " ")
  end
end
