class Species
  attr_reader :raw, :genus, :s_epithet, :type, :original_genus, :citation,
              :type_locality, :family, :order, :extinct, :file
  def initialize(g, s, file = nil)
    @file = file
    @extinct ||= false

    # Deal with comments
    while s.children.find{|n| n.name == 'comment'}
      comment = s.children.find{|n| n.name == 'comment'}
      comment.remove
      if comment.text.match(/^ *[T,t].?[L,l]/)
        @type_locality = comment.text
      else
        # Do something with other comments
      end
    end

    # PARSING NAME
    name = s.children[0].text.split(" ")
    @family = g.family
    @order = g.order
    @genus = name[0]

    # Check to see if Genera match up
    # binding.pry if @genus != g.name

    # NEED TO GENERALIZE EXTINCT MARKER PARSING

    # If multiple words to name, first word genus, second sp. epithet
    if name.length > 1
      @s_epithet = name[1]
      if @s_epithet[-1] == "†"
        @extinct = true
        @s_epithet = @s_epithet[0..-2].strip
      end
      @original_genus = name[-1] != "("
      @citation = Citation.new(s.children[1..-1]) # Send rest to citation
    else
      # If not multiple words to name, Check for bold node denoting type
      if s.children[1].name == 'b'
        @type = true
        @s_epithet = s.children[1].text

        if s.children[2].name == 'text' and s.children[2].text.include?("(")
          @original_genus = false
          @citation = Citation.new(s.children[3..-1])
        else
          @original_genus = true
          @citation = Citation.new(s.children[2..-1]) # Send rest to citation
        end
      else
        binding.pry
        raise "Incomplete Name: #{s.text}" # Error checking
      end
    end

    # binding.pry
    # @raw = s
  end

  def to_s
    "#{@file} #{@genus} #{@s_epithet} #{@ss_epithet}"
  end

  def name
    [genus, s_epithet]
  end
end
