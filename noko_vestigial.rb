
def error_parse(d)
  order_node = d.css('h1')[0]
  begin
    order = Order.new(order_node)
  rescue
    order = {"ORDER NOT PARSED" => order_node}
  end

  families = d.css('h2')
  genera = d.css('h4')

  genus_families = error_find_genera_families(families, genera)

  parsed = []
  parsed << order
  family = nil
  genera.each_with_index do |g, idx|
    if idx == 0
      family = genus_families[idx]
      parsed << family
    else
      if genus_families[idx] != family
        family = genus_families[idx]
        parsed << family
      end
    end

    begin
      order_name = order.name
    rescue
      order_name = {"ORDER NAME NOT PARSED" => order}
    end

    begin
      family_name = family.name
    rescue
      family_name = {"FAMILY NAME NOT PARSED" => family}
    end

    begin
      if order_name.class == Hash
        genus_object = order_name.merge({"g" => g})
      elsif family_name.class == Hash
        genus_object = family_name.merge({"g" => g})
      else
        genus_object = Genus.new(order.name, family.name, g)
      end
    rescue
      genus_object = {"GENUS NOT PARSED" => [order_name, family_name, g]}
    end
    parsed << genus_object
    species_list = find_next(g, 'ul')

    species = species_list.children.select{ |c| c.name != 'text'}

    if genus_object.class == Hash
      parsed << {"INVALID GENUS; NO SPECIES" => species}
    else
      species.each do |s|
        if s.name == 'li'
          unless s.text.strip == ''
            begin
              sp = Species.new(genus_object, s)
            rescue
              sp = {"SPECIES NOT PARSED" => [genus_object, s]}
            end
            parsed << sp
          end
        elsif s.name == 'ul'
          parsed += error_parse_subspecies(genus_object, s)
        end
      end
    end
  end

  checklist_notes = find_checklist_notes(order_node)
  order.add_checklist_notes(checklist_notes)

  parsed

end

def error_parse_subspecies(g, s)

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
      binding.pry
    end
  end

  subspecies = subspecies.map do  |s|
    begin
      sub = Subspecies.new(g, s)
    rescue
      sub = {"SUBSP NOT PARSED" => [g,s]}
    end
    sub
  end

  # pry_break(subspecies.last.ss_epithet, "resplendens")

  subspecies
end


def error_find_genera_families(families, genera)
  genus_families = []
  trailing_index = 0
  families.each_with_index do |fam_node, idx|
    if idx != 0
      begin
        f = Family.new(families[idx-1])
      rescue
        f = {"FAMILY NOT PARSED" => families[idx-1]}
      end

      first_genus = find_next(fam_node, 'h4')

      if first_genus == nil
        binding.pry
      end

      gen_index = genera.index(first_genus)
      num_genera = gen_index - trailing_index
      genus_families += [f] * num_genera

      trailing_index = gen_index
    end

    if idx == (families.length - 1)
      begin
        f = Family.new(fam_node)
      rescue
        f = {"FAMILY NOT PARSED" => fam_node}
      end
      genus_families += [f] * (genera.length - genus_families.length)
    end
  end
  genus_families
end
# p, n  = parse_document(d)
# names = p.map{ |t| t.to_s}
# binding.pry

# binding.pry
#
# g = Genus.new(order.name, family_name, genus[0])
# genus_name = genus.children[0].text
# genus_gender = genus.children[1].text
# genus_author = genus.children[3]
# genus_year = genus.children.find { |c| c.text[0..1] == " 1" || c.text[0..1] == " 2"}
# citon_start = genus.children.index(genus_year)+1
#
# links = genus.children[citon_start..-1].select{ |c| c[:href] != nil || c.children.any?{ |cc| cc[:href] != nil}}
# citon_end = links.length >1 ? genus.children.index(links[1]) -1 : -1
#
# citon = genus.children[citon_start..citon_end]

# species =
# subspecies = d.css('ul ul li')
# all_li = d.css('ul li')
#
# other_li = all_li.select{ |li| !subspecies.include?(li)}
#
# first_taxa_list = nil
# search_node = order
# until first_taxa_list
#   if search_node.name == 'ul'
#     first_taxa_list = search_node
#   end
#   search_node = search_node.next_element
# end
# first_sp = first_taxa_list.children.css('li')[0]
#
# sp_index = other_li.find_index(first_sp)
#
# species = other_li[sp_index..-1]
# checklist_notes = other_li[0..(sp_index-1)]


# other_li.each{ |li| puts li.text}


# reader = Nokogiri::XML::Reader(open("http://www.zoonomen.net/avtax/stru.html"))
# reader = Nokogiri::XML::Reader(open("./tina.html"))
# after_order = false
# reader.each do |node|
#
#   puts node.name
#   if node.name == 'h1' and node.inner_xml != ""
#     if after_order
#       raise 'Order already assigned'
#     end
#     o_name = node.inner_xml
#     unless o_name.split(" ").length == 1
#       o_name, o_auth, o_year = o_name.split(" ")
#     end
#
#     after_order = true
#     binding.pry
#   end
#
#   # if node.name == 'h2' and node.inner_xml
#
#
# end # end Reader each
# binding.pry
