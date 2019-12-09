require 'pry'
require './citation'
require './note'
class Genus
  attr_reader :name, :gender, :author, :year, :citation, :family, :order, :extinct, :file

  def initialize(order, family, e, file = nil)
    @file = file
    @extinct = false
    @order = order
    @family = family
    @name = e.children[0].text.strip

    # Need to generalize dealing with extinct designation
    if @name[-1] == "†"
      @extinct = true
      @name = @name[0..-2].strip
    end

    g = e.children[1].text
    # binding.pry
    # Ony m,f,n for gender?
    if g.match(/\([m,f,n,a].\)/)
      @gender = g[1]
      @citation = Citation.new(e.children[2..-1])
      unless @gender == 'f' or @gender == 'm' or @gender == 'n' or @gender == 'a'
        raise "Incorrect gender parse for #{@name}"
      end
    else
      # binding.pry
      puts "NO GENDER FOR #{@name}"
      @citation = Citation.new(e.children[1..-1])
    end

    # binding.pry
  end

  def to_s
    "#{@file} GENUS: #{@order} #{@family} #{@name}"
  end
end
