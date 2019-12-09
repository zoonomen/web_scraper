require './species'
class Subspecies < Species
  attr_reader :ss_epithet
  def initialize(g, s, file = nil)
    name = s.children[0].text.split(" ")
    @ss_epithet = name.delete_at(2)
    if @ss_epithet[-1] == "†"
      @extinct = true
      @ss_epithet = @ss_epithet[0..-2].strip
    end
    s.children[0].content = name.join(" ")
    # binding.pry
    super(g, s, file)
  end

  def name
    super << ss_epithet
  end
end
