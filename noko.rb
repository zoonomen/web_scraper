require 'nokogiri'
require 'pry'
require 'open-uri'
require './genus'
require './family'
require './species'
require './subspecies'
require './order'
require './error.rb'

def find_next(current_node, css_tag)
  until current_node.name == css_tag
    current_node = current_node.next
  end
  current_node
end

def pry_break(value, condition)
  if value == condition
    binding.pry
  end
end

def parse_subspecies(g, s, file, error_parsing)

  if s.children[0].name == 'small'
    subspecies = s.children[0].children
  else
    subspecies = s.children
  end

  subspecies = subspecies.select{|c| c.name == 'li' or c.name == 'comment'}

  while subspecies.find{|n| n.name == 'comment'}
    comment_index = subspecies.index{|n| n.name == 'comment'}
    comment = subspecies.delete_at(comment_index)

    if comment.text.match(/[T,t].?[L,l]/)
      subspecies[comment_index - 1].add_child(comment)
    else
      # If there is some other type of comment go into pry session

      ## Should simply add to child? not check for TL comment?
      # binding.pry
    end
  end

  subspecies = subspecies.map do |s|
    arguments = [g,s,file]
    begin
      sub = Subspecies.new(*arguments)
    rescue
      error = 'SUBSP NOT PARSED'
      if error_parsing
        sub = Error.new(file, error, arguments)
      else
        raise error
      end
    end
    sub
  end

  # pry_break(subspecies.last.ss_epithet, "resplendens")

  subspecies
end

def find_genera_families(families, genera, file, error_parsing)
  genus_families = []
  trailing_index = 0
  families.each_with_index do |fam_node, idx|
    if idx != 0
      argument = families[idx-1]
      begin
        f = Family.new(argument)
      rescue
        error = 'FAMILY NOT PARSED'
        if error_parsing
          f = Error.new(file, error, argument)
        else
          raise error
        end
      end
      # binding.pry
      first_genus = find_next(fam_node, 'h4')

      gen_index = genera.index(first_genus)
      num_genera = gen_index - trailing_index
      genus_families += [f] * num_genera

      trailing_index = gen_index
    end
    if idx == (families.length - 1)
      argument = fam_node
      begin
        f = Family.new(argument)
      rescue
        error = 'FAMILY NOT PARSED'
        if error_parsing
          f = Error.new(file, error, argument)
        else
          raise error
        end
      end

      genus_families += [f] * (genera.length - genus_families.length)
    end
  end
  genus_families
end

def find_checklist_notes(order_node)
  current_node = order_node

  until current_node == nil or current_node.name == 'ul'
    current_node = current_node.previous
  end

  if current_node
    checklist_notes = current_node
  else
    checklist_notes = "No Checklist Notes"
  end
  checklist_notes
end

def parse_document(d, file = nil, error_parsing = false)
  # binding.pry
  # Order is within <h1> tag
  order_node = d.css('h1')[0]

  # Families are within <h2> Tags
  families = d.css('h2')
  # Genera are within <h4> Tags
  genera = d.css('h4')

  begin
    order = Order.new(order_node)
  rescue
    binding.pry
    error = "ORDER NOT PARSED"
    if error_parsing
      order = Error.new(file, error, order_node)
    else
      raise error
    end
  end
  #######
  # Ignoring Subfamilies within <h3> Tags
  #######

  # Below determines which Genera belong to which Families (Not parsing document sequentially)
  # Returns a list of families that is the number of genera long. e.g
  # [fam1, fam1, fam2, fam3, fam3, fam3]
  genus_families = find_genera_families(families, genera, file, error_parsing)

  # This is my list of taxa from the file
  parsed = []
  # Order is first taxa ranked taxa
  # (Not worrying about Passer files -- Yet, will be one-off fix)
  parsed << order
  family = nil

  # Going through each of the genera
  genera.each_with_index do |g, idx|
    # If the Family has changed Added it to the list of taxa
    if idx == 0
      family = genus_families[idx]
      parsed << family
    else
      if genus_families[idx] != family
        family = genus_families[idx]
        parsed << family
      end
    end

    order_name = order.name
    if order_name == nil
      error = "ORDER NAME NOT PARSED"
      order_name = Error.new(file, error, order)
      raise error unless error_parsing
    end

    family_name = family.name
    if family_name == nil
      error = "FAMILY NAME NOT PARSED"
      family_name = Error.new(file, error, order)
      raise error unless error_parsing
    end

    # Add the Genus
    begin
      if order_name.class == Error
        genus_object = order_name.add_info({g: g})
      elsif family_name.class == Error
        genus_object = family_name.add_info({g: g})
      else
        genus_object = Genus.new(order_name, family_name, g, file)
      end
    rescue
      error = "GENUS NOT PARSED"
      if error_parsing
        genus_object = Error.new(file, error, [order_name, family_name, g, file])
      else
        raise error
      end
    end
    parsed << genus_object

    # Find the <ul> after the genus
    species_list = find_next(g, 'ul')

    # Only select "nodes" that are note pure text --- text nodes usually just spaces
    species = species_list.children.select{ |c| c.name != 'text'}

    if genus_object.class == Error
      parsed << Error.new(file, "INVALID GENUS; NO SPECIES", species)
    else
    # Go through each of the nodes
      species.each do |s|
        # If its a <li> it's a species
        if s.name == 'li'
          # Check to make sure <li> not empty
          #### ADD FLAG?? #####
          unless s.text.strip == ''
            begin
              sp = Species.new(genus_object, s, file)
            rescue
              error = "SPECIES NOT PARSED"
              if error_parsing
                sp = Error.new(file, error, [genus_object, s, file])
              else
                raise error
              end
            end
            parsed << sp
          end
        # If it's a <ul>, it's a list of subspecies. Send to function to parse SS
        elsif s.name == 'ul'
          parsed += parse_subspecies(genus_object, s, file, error_parsing)
        else
          #### ADD FLAG?? #####
          # binding.pry
        end
      end
    end
  end

  # Find notes of checklist
  # Associate with the order
  checklist_notes = find_checklist_notes(order_node)
  if order.class == Order
    order.add_checklist_notes(checklist_notes)
  end

  # Return the list of parsed taxa
  parsed
end
