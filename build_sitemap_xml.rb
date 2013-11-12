#!/usr/bin/env ruby
#
require 'date'
require 'time'
require 'nokogiri'

SiteUrl = 'http://aerostitch.github.io'
# This is to ensure we are in the same directory as the script
# to enable people to run the script from another directory
script_path = File.dirname(File.expand_path($0))

# This function will get the content of the revdate in the html documents
# Returns a date if a revdate tag is found, else returns nil. 
def get_revdate(doc_path)
  doc = Nokogiri::HTML(File.open(doc_path)) { |config| config.strict.nonet}
  revdate = doc.search('//span[@id="revdate"]').text.strip
  DateTime.strptime(revdate, '%Y-%m-%d') if /^\d{4}-\d{2}-\d{2}$/.match(revdate)
end

Dir.chdir(script_path)

# Process starts here...
# This gets all the html files and their modification date
doc = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.urlset('xmlns' => "http://www.sitemaps.org/schemas/sitemap/0.9",
    'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
    'xsi:schemaLocation' => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd") do
    Dir.glob('../**/*.html')
      .delete_if { |fname| /(\/|^)_/.match(fname) or /_(\/|$)/.match(fname) }
      .sort
      .each { |file|
        xml.url{
          xml.loc(file.gsub(/\.\./,SiteUrl))
          # For index.html files, use the description.inc file modification date
          # instead
          fdesc = file.gsub(/index\.html$/,'description.inc')
          if file != fdesc and File.exists?(fdesc)
            xml.lastmod((File.new(fdesc).mtime).iso8601)
          else
            # If a revision date is found in the doc, use it.
            # Else, use the file last modification date
            dte = get_revdate(file)
            if dte.nil?
              xml.lastmod((File.new(file).mtime).iso8601)
            else
              xml.lastmod((get_revdate(file)).iso8601)
            end
          end
          xml.changefreq('monthly')
          xml.priority('1.0')
        }
      }
  end
end

# Finally writing menu.xml file
begin
  file = File.open("../sitemap.xml", "w")
  file.write(doc.to_xml)
rescue IOError => e
  puts "[Error] Could not open file."
  puts e.message
ensure
  file.close unless file == nil
end
