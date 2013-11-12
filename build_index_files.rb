#!/usr/bin/env ruby
#
require 'nokogiri'
require 'json'

# This is to ensure we are in the same directory as the script
# to enable people to run the script from another directory
script_path = File.dirname(File.expand_path($0))
Dir.chdir(script_path)
Www_root = File.expand_path(script_path +'/..')


# Tansforms a subfolder into a hashtable conatining its files and folders
# It uses a recursive call
def gen_subfolders_node(parent_path)
  nodes = []
  # Going back from the tool dir to the root dir
  Dir.chdir(parent_path) do
    current_fullpath = Dir.pwd
    Dir.glob('*')
      .delete_if { |fname| /(\/|^)_/.match(fname) or /_(\/|$)/.match(fname) }
      .delete_if { |fname| /asciidoc_twbs_backend/.match(fname) }
      .delete_if { |fname| /bysas/.match(fname) }
      .select {|f| File.directory? f}
      .sort
      .each { |fold|
        f_childs =  gen_files_nodes("#{current_fullpath}/#{fold}");
        d_childs = gen_subfolders_node("#{current_fullpath}/#{fold}");
        #  name: fold.capitalize, url: "#{current_fullpath}/#{fold}".gsub(Www_root,''), target: :_self,
        nodes << {
          name: fold.capitalize,
          children: f_childs + d_childs
        }
      }
  end
  nodes
end

# Transforms the files of the given directory into an hashtable
# Filters files begining or ending with an "_" and the "index.html" files
def gen_files_nodes(dir)
  nodes = []
  Dir.chdir(dir) do
    current_fullpath = Dir.pwd
    Dir.glob('*.html')
      .delete_if { |fname| 
        /(\/|^)_/.match(fname) or /_(\/|$)/.match(fname) or
        /index\.html$/.match(fname)
      }
      .delete_if { |fname| /asciidoc_twbs_backend/.match(fname) }
      .delete_if { |fname| /bysas/.match(fname) }
      .sort
      .each { |file|
        doc = Nokogiri::HTML(File.open(file)) { |config| config.strict.nonet}
        title = doc.search('//html/head/title').text
        url = "#{current_fullpath}/#{file}".gsub(/\.\./,'').gsub(Www_root,'')
        nodes << { name: title, url: url, target: :_self }
      }
  end
  nodes
end

# This gets all the html files and their modification date
def build_index_files(idx_root)
  Dir.chdir(idx_root) do
    idx_root = Dir.pwd
    files = gen_files_nodes(idx_root)
    folders = gen_subfolders_node(idx_root)
    json_content = files + folders
    
    # Finally writing index.json file
    idx_file = "#{idx_root}/index.json"
    begin
      file = File.open(idx_file, "w")
      file.write(JSON.pretty_generate(json_content))
    rescue IOError => e
      puts "[Error] Could not open file."
      puts e.message
    ensure
      file.close unless file.nil?
    end
  end
end

# Adds the content of a file (located at file_path) to the given html_obj
# for all nodes matching the node_path
def add_file_content_to_node(html_obj, node_path, file_path)
  html_obj.search(node_path).each do |node|
    if File.exist?(file_path)
      node << File.read(file_path)
    else
      puts "[INFO] no #{file_path} file found"
    end
  end
end

# adds the description to the document if description.inc exists
def update_index_html_description(fold_path)
  idx_html = File.open("#{Www_root}/asciidoc_twbs_backend/templates/index.html",'r')
  doc = Nokogiri::HTML(idx_html) { |config| config.strict.nonet}
  idx_html.close()  # File have to be closed to rewrite data in it
  # Adding description content
  add_file_content_to_node(doc, '//div[@id="Description"]',
                           "#{fold_path}/description.inc")
  # Adding the content of google_tags.inc
  # which contains the html headers for google meta tag validation
  # but could also contain google analytics code for example
  # It is added to all index.html pages because 
  add_file_content_to_node(doc, '/html/head',
                           "#{Www_root}/bysas/google_tags.inc")
  # Writing result to the index.html file
  begin
    outfile = File.open("#{fold_path}/index.html",'w')
    outfile.write(doc.to_xml)
  rescue IOError => e
    puts "[Error] proceeding to update of file #{fold_path}/index.html:"
    puts e.message
  ensure
    outfile.close unless outfile.nil?
  end
end

# Now building index.xml files and customizing index.html files
build_index_files(Www_root)
Dir.glob([Www_root,"#{Www_root}/**/*"])
  .delete_if { |fname| /(\/|^)_/.match(fname) or /_(\/|$)/.match(fname) }
  .delete_if { |fname| /asciidoc_twbs_backend/.match(fname) }
  .delete_if { |fname| /bysas/.match(fname) }
  .select { |f| File.directory? f }
  .sort
  .each { |fold|
    # Deploying index.html template file and adding customizations to
    # index.html pages
    update_index_html_description(fold)
  }

