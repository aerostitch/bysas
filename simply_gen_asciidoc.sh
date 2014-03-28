#!/usr/bin/env bash
# This is just to regenerate asciidocs while creating the backend.
# Then Rasciidoc (https://github.com/llicour/raskiidoc) will be used.
# For now it's only available in the git version of asciidoc
find ../ -name '*.adoc' -and -not -name 'Notes.adoc' -and -not -name \
'doc_template.adoc' -exec asciidoc \
--conf-file=../asciidoc_twbs_backend/asciidoc_twbs_backend.conf \
-b html5  \
-a toc \
-a toclevels=3 \
-a doctype=article \
-a data-uri \
-a ascii-ids \
-a linkcss \
-a stylesdir=/asciidoc_twbs_backend/css \
-a scriptsdir=/asciidoc_twbs_backend/js \
-a icons \
-a iconsdir=/asciidoc_twbs_backend/ico \
-a numbered \
-a lang=en \
-a encoding=UTF-8 \
-a website=http://aerostitch.github.io \
-a footer-style=none \
{} \;

ruby build_index_files.rb 
ruby build_menu_xml.rb
ruby build_sitemap_xml.rb 

