#!/usr/bin/env ruby
#

require 'nokogiri'
# This is to ensure we are in the same directory as the script
# to enable people to run the script from another directory
script_path = File.dirname(File.expand_path($0))
Dir.chdir(script_path)

# This function builds recursively an xml containing all folders of the website
def gen_subfolders_node(parent_dir, parent_node)
  # Going back from the tool dir to the root dir
  Dir.chdir(parent_dir) do
    current_fullpath = Dir.pwd
    
    # building tree
    subfolders = Dir.glob('*')
      .delete_if { |fname| /(\/|^)_/.match(fname) or /_(\/|$)/.match(fname) }
      .delete_if { |fname| /asciidoc_twbs_backend/.match(fname) }
      .delete_if { |fname| /bysas/.match(fname) }
      .select { |filename| File.directory? filename }
      .each { |fold|
        # child = parent_node.add_element 'url';
        # ti = child.add_element 'loc';
        # ti.text = fold;
        parent_node.send('url') do
          parent_node.title(fold.gsub(/_/, " ").capitalize)
          parent_node.path(fold)
          gen_subfolders_node("#{current_fullpath}/#{fold}", parent_node);
        end
      }
  end
end

# Process starts here...
doc = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.urlset do
    xml.url {
      xml.title "Home"
      xml.path ""
    }
    gen_subfolders_node('..', xml)
  end
end

# Finally writing menu.xml file
begin
  file = File.open("../menu.xml", "w")
  file.write(doc.to_xml)
rescue IOError => e
  puts "[Error] Could not open file."
  puts e.message
ensure
  file.close unless file == nil
end
