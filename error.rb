class Error
  attr_reader :type, :data, :file
  def initialize(file, type, info)
    @file = file
    @type = type
    if info.class == Array
      @info = info
    else
      @info = [info]
    end
  end

  def to_s
    "ERROR in #{@file}\n"+
    "TYPE: #{@type}\n"+
    "INFO:\n"+
    info_string
  end

  def info_string
    @info.map do |i|
      if (i.class == Nokogiri::XML::NodeSet) or (i.class == Nokogiri::XML::Element)
        "- #{i.text}\n"
      else
        "- #{i.to_s}\n"
      end
    end.join("")
  end

  def add_info(new_info)
    @info << new_info
  end
end
