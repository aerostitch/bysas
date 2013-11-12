#!/usr/bin/env bash
# This is just to regenerate asciidocs while creating the backend.
# Then Rasciidoc (https://github.com/llicour/raskiidoc) will be used.
find ../ -name '*.adoc' -and -not -name 'Notes.adoc' -and -not -name \
'doc_template.adoc' -exec asciidoc \
--conf-file=../asciidoc_twbs_backend/asciidoc_twbs_backend.conf \
-b html5 {} \;

ruby build_index_files.rb 
ruby build_menu_xml.rb
ruby build_sitemap_xml.rb 

