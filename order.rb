require './citation'
# Orders, split on spaces, First word is name, the rest is citation
class Order
  attr_reader :name, :citation, :checklist_notes
  def initialize(ord_node)
    split_string = ord_node.text.split(" ")
    @name = split_string[0]
    @citation = Citation.new(split_string[1..-1].join(" "))
  end

  def add_checklist_notes(cl_n)
    @checklist_notes = cl_n
  end

  def to_s
    @name
  end
end
