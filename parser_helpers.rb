def reset_multi_citons
  File.new('multi_cite.txt', 'w+')
  File.new('non_multi_cite.txt', 'w+')
end

PageLink = Struct.new(:name, :path)
Counter = Struct.new(:key, :count)

def find_page_links(start_group, end_group, file = './toc.html')
  links = Nokogiri::HTML.parse(open(file)).css('a')

  start_idx = link_index(links, start_group)
  end_idx = link_index(links, end_group)
  pages = links[start_idx..end_idx]

  page_links = pages.map{|p| PageLink.new(p.text, p.attributes['href'].value)}

  page_links
end

def link_index(links, text)
  links.index{|e| e.text == text}
end

def find_or_create_key(hash, key, default)
  hash[key] = default unless hash.keys.include?(key)
  hash
end

def check_link_ok(link, downloader)

  base = 'http://www.zoonomen.net/'
  suffix, anchor_name = link.split("#")
  split = suffix.split("/")

  bio_index = split.index("bio")
  avtax_index = split.index("avtax")
  cit_index = split.index('cit')
  # binding.pry
  if bio_index
    suffix = split[(bio_index+1)..-1].join("/")

    data = downloader.author_data(suffix)
  elsif avtax_index
    suffix = split[(avtax_index+1)..-1].join("/")
    data = downloader.taxa_data(suffix)
  elsif cit_index
    suffix = split[(cit_index+1)..-1].join("/")
    data = downloader.cit_data(suffix)
    # binding.pry
  else
    puts "INVALID LINK #{link}"
    return false
  end


  ad = Nokogiri::HTML.parse(data)

  begin
    anchor = ad.css('a').find do |e|
      e.attributes['name'] != nil and e.attributes['name'].value == anchor_name
    end
    notes = []
    node = anchor.next
    while node and node.name != 'hr'
      notes << node
      node = node.next
    end
    return notes.join("") != ''
  rescue
    return false
  end

end

def build_report(parsed_list, taxa_functions, report_name)
  downloader = Downloader.new
  none_present = {Family => [], Order =>[], Genus => [], Species =>[], Subspecies => []}
  by_name = {}
  by_link = {}
  no_link = {}
  bad_link = []
  parsed_list.keys.each do |key|
    taxa = parsed_list[key][1]
    taxa.each do |t|
      info = t
      taxa_functions.each do |f|
        if info.class == Array
          info = info.map{|i| i.send(f)}
        else
          info = info.send(f)
        end
        break if info == nil
      end

      if info == nil or (info.class == Array and info.count == 0)
        taxa_class = t.class
        none_present[taxa_class] << t.to_s
      else
        info = [info] unless info.class == Array
        info.each do |i|
          name = i.name
          link = i.link

          if link
            # binding.pry
            bad_link << [link,t] unless check_link_ok(link, downloader)

            find_or_create_key(by_name, name, {})
            find_or_create_key(by_name[name], link, [])
            by_name[name][link] << t.to_s

            find_or_create_key(by_link, link, {})
            find_or_create_key(by_link[link], name, [])
            by_link[link][name] << t.to_s
          else # no link
            find_or_create_key(no_link, name, [])
            no_link[name] << t.to_s
          end
        end
      end
    end
  end

  binding.pry
  # multi_links = find_multi_entries(by_name)
  # multi_names = find_multi_entries(by_link)

  generate_report(report_name + "_multi_links.txt", "name", by_name)
  generate_report(report_name + "_multi_names.txt", "link", by_link)
end

def find_multi_entries(hash)
  hash.find_all do |k,v|
    v.length >1
  end
end

def generate_report(name, kind, collection)
  report = []
  hash = find_multi_entries(collection)

  hash.each do |k,v|
    key_order = v.keys.inject([]) do |arr, key|
      arr << Counter.new(key, v[key].count)
      arr
    end.sort_by{|a| a[1]}.reverse

    to_ret = "The #{kind} #{k} is associated with "
    taxa_list = "\n\n----LOCATION SPECIFICS---\n"
    key_order.each_with_index do |counter, idx|
      to_ret += "\n- #{counter.key} #{counter.count} times;"

      if (idx > 0 or counter.count <= 5) and counter.count < 10
        taxa_list += "\n#{counter.key} is found in: \n- #{v[counter.key].join(";\n- ")}"
      end
    end

    report << to_ret + taxa_list + "\n\n-------------\n\n"

  end

  File.open(name, 'w+') do |f|
    report.each{|r| f.puts(r)}
  end
  # binding.pry
end
  ##################
  # Find taxa without
  # Sort and collect by name
  # Sort and collect by link
  # Ensure links have appropriate associated information
  ##################

def build_author_report(parsed_list)
  build_report(parsed_list, [:citation, :authors], 'authors')
end

def build_journal_report(parsed_list)
  build_report(parsed_list, [:citation, :journal_location, :journal], 'journals')
end
# def build_author_report(parsed_list)
#   no_author = {Family => [], Order =>[], Genus => [], Species =>[], Subspecies => []}
#
#   authors_by_name = {}
#   authors_by_link = {}
#   parsed_list.keys.each do |key|
#     taxa = parsed_list[key][1]
#     taxa.each do |t|
#       authors = t.citation.authors
#       if authors == nil or authors.count == 0
#         taxa_class = t.class
#         no_author[taxa_class] << t.to_s
#       else
#
#         authors.each do |a|
#           name = a.name
#           link = a.link
#
#           next unless link
#           unless authors_by_name.keys.include?(name)
#             authors_by_name[name] = {}
#           end
#
#           unless authors_by_name[name].keys.include?(link)
#             authors_by_name[name][link] = []
#           end
#           authors_by_name[name][link] << t.to_s
#
#
#           unless authors_by_link.keys.include?(link)
#             authors_by_link[link] = {}
#           end
#
#           unless authors_by_link[link].keys.include?(name)
#             authors_by_link[link][name] = []
#           end
#           authors_by_link[link][name] << t.to_s
#         end
#       end
#     end
#   end
#
#   multi_links = {}
#   authors_by_name.each do |k, v|
#     if v.length > 1
#       multi_links[k] = v
#     elsif v.length == 0
#       binding.pry
#     end
#   end
#
#   multi_names = {}
#   authors_by_link.each do |k, v|
#     if v.length > 1
#       multi_names[k] = v
#     elsif v.length == 0
#       binding.pry
#     end
#   end
#
#   names_report = []
#   multi_names.each do |k,v|
#     key_order = v.keys.inject([]) do |arr, key|
#       arr << Counter.new(key, v[key].count)
#       arr
#     end.sort_by{|a| a[1]}.reverse
#
#     to_ret = "The link #{k} is associated with "
#     taxa_list = ""
#     key_order.each_with_index do |counter, idx|
#       to_ret += "#{counter.key} #{counter.count} times; "
#
#       if (idx > 0 or counter.count <= 5) and counter.count < 10
#         taxa_list += "\n#{counter.key} is found in #{v[counter.key].join("; ")}"
#       end
#     end
#
#     names_report << to_ret + taxa_list + "\n-------------\n\n"
#
#   end
#   binding.pry
# end


def build_note_report(parsed_list)
  note_names = Hash.new(0)
  note_name_taxa = {}
  parsed_list.keys.each do |key|
    taxa = parsed_list[key][1]
    taxa.each do |t|
      notes = t.citation.notes

      if notes
        notes.each do |n|
          name = n.name
          note_names[name] += 1
          unless note_name_taxa.keys.include?(name)
            note_name_taxa[name] = []
          end
          note_name_taxa[name] << t
        end
      end
    end
  end

  note_list = []

  # approved_words = [
  #   "Type", "Concept", "Citation", "Nomenclature",
  #   "Systematics", "Author", "Extinct"
  # ]

  note_targets = note_names.map{|k,v| [k,v]}.select{|e| e[1] < 5}.map{|e| e[0]}

  note_targets.each do |target|
    note_list << "NOTE: #{target}\n----------"
    taxa = note_name_taxa[target]
    taxa.each do |tax|
      note_list << "- #{tax}\n"
    end
    note_list << "\n"
  end

  File.open("note_report.txt", "w+") do |f|
    note_list.each{|e| f.puts(e)}
  end
  # binding.pry
end
