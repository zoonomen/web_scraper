require './citation'
# Family, split on spaces, First word is name, the rest is citation
class Family
  attr_reader :name, :citation
  def initialize(fam_node)
    split_string = fam_node.text.split(" ")
    @name = split_string[0]

    # Will need to populate author citation link
    # Need to add Journal to citation?
    @citation = Citation.new(split_string[1..-1].join(" "))
  end

  def to_s
    @name
  end
end
