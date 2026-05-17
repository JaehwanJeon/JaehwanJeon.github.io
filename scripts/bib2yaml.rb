#!/usr/bin/env ruby
# Convert _bibliography/papers.bib -> structured publications data + one
# consistent citation string per entry. No plugins; run this whenever the
# .bib changes.  Usage: ruby scripts/bib2yaml.rb [out.yml]
require 'yaml'

BIB = File.join(__dir__, '..', '_bibliography', 'papers.bib')
OUT = ARGV[0] || File.join(__dir__, '..', '_data', 'publications.yml')

TYPE_TO_CATEGORY = {
  'article' => 'manuscripts', 'inproceedings' => 'conferences',
  'phdthesis' => 'thesis', 'unpublished' => 'underreview'
}

def parse_bib(text)
  entries = []
  text.scan(/@(\w+)\s*\{\s*([^,]+),(.*?)\n\}/m) do |type, key, body|
    fields = {}
    (body + "\n").scan(/(\w+)\s*=\s*\{(.*?)\}\s*,?\s*\n/m) { |k, v| fields[k.downcase] = v.strip.gsub(/\s+/, ' ') }
    entries << { 'type' => type.downcase, 'key' => key.strip, 'fields' => fields }
  end
  entries
end

# un-escape common LaTeX/BibTeX: \& -> & , -- -> en-dash
def tex(s) = s.to_s.gsub('\\&', '&').gsub('--', "–")

# "Jaehwan" -> "J." ; "Oh-Sung" -> "O."
def initials(given) = given.split(/\s+/).map { |g| g[0].upcase + '.' }.join(' ')

def format_authors(raw, corresponding)
  people = raw.split(/\s+and\s+/).map(&:strip)
  formatted = people.each_with_index.map do |p, i|
    last, given = p.include?(',') ? p.split(',', 2).map(&:strip) : [p.split.last, p.split[0..-2].join(' ')]
    name = i.zero? ? "#{last}, #{initials(given)}" : "#{initials(given)} #{last}"
    name += '*' if corresponding && last == corresponding
    name
  end
  return formatted.first if formatted.size == 1
  formatted[0..-2].join(', ') + ', and ' + formatted[-1]
end

entries = parse_bib(File.read(BIB)).map do |e|
  f = e['fields']
  cat = TYPE_TO_CATEGORY[e['type']] || 'manuscripts'
  authors = format_authors(f['author'], f['corresponding'])
  year = f['year']
  title = tex(f['title'])
  venue = tex(f['journal'] || f['booktitle'] || f['school'])
  venue = 'Under review' if cat == 'underreview'
  paperurl = f['doi'] ? "https://doi.org/#{f['doi']}" : f['url']

  citation =
    case cat
    when 'manuscripts'
      c = "#{authors} (#{year}). #{title}. #{venue}."
      if f['volume']
        v = " Vol. #{f['volume']}"
        v += ", No. #{f['number']}" if f['number']
        v += ", #{f['pages']}" if f['pages']
        v += ", #{f['articleno']}" if f['articleno']
        c += v + "."
      end
      c
    when 'conferences'
      [ "#{authors} (#{year})", title, venue, f['eventdate'], f['address'] ].compact.join(', ') + '.'
    when 'thesis'
      "#{authors} (#{year}). #{title}. Doctoral dissertation, #{venue}."
    when 'underreview'
      "#{authors}. #{title}. (Under review)."
    end

  {
    'title' => title, 'category' => cat, 'date' => f['date'],
    'venue' => venue,
    'note' => (cat == 'underreview' ? nil : f['note']),
    'presentation' => f['presentation'],
    # short summary shown only for journal articles (via .bib `abstract`)
    'excerpt' => (cat == 'manuscripts' ? tex(f['abstract']) : nil),
    'paperurl' => paperurl, 'citation' => citation
  }.compact
end

# newest first by date (stable within a year via the ISO date field)
entries.sort_by! { |x| x['date'].to_s }
entries.reverse!

header = "# GENERATED from _bibliography/papers.bib by scripts/bib2yaml.rb — DO NOT EDIT.\n" \
         "# Edit the .bib and re-run:  ruby scripts/bib2yaml.rb\n\n"
File.write(OUT, header + entries.to_yaml.sub(/\A---\n/, ''))
puts "Wrote #{entries.size} entries -> #{OUT}"
entries.each { |x| puts "\n[#{x['category']}] #{x['citation']}" + (x['note'] ? "   <note at title: #{x['note']}>" : '') }
