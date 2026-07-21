#!/usr/bin/env ruby
# Generate the LaTeX source for the PDF CV from homepage data.
# Layout mirrors the hand-made CV.pdf (sections A–I, J#/C-I#/C-D# numbering).
#
# Sources:
#   _pages/cv.md            -> Education / Work experience / Honors (Selected)
#   _data/publications.yml  -> dissertation, journals, under review, conferences
#   _data/talks.yml         -> invited talks & seminars
#   _data/teaching.yml      -> TA terms (merged into Professional Experience)
#   _data/cv_extra.yml      -> personal details, KATUSA, scholarships, patents, OSS
#
# Runs on stock macOS ruby (2.6, stdlib only). Usage:
#   ruby scripts/build_cv_pdf.rb [out.tex]     (normally via build_cv_pdf.sh)
require 'yaml'
require 'date'
require 'fileutils'

ROOT = File.expand_path(File.join(__dir__, '..'))
OUT  = ARGV[0] || File.join(ROOT, '.cv_build', 'cv.tex')

extra    = YAML.load_file(File.join(ROOT, '_data', 'cv_extra.yml'))
pubs     = YAML.load_file(File.join(ROOT, '_data', 'publications.yml'))
talks    = YAML.load_file(File.join(ROOT, '_data', 'talks.yml')) || []
teaching = YAML.load_file(File.join(ROOT, '_data', 'teaching.yml')) || []
cvmd     = File.read(File.join(ROOT, '_pages', 'cv.md'))

# ---------------------------------------------------------------- helpers ---
def esc(s)
  s = s.to_s
  s = s.gsub('\\', "\x00")
  s = s.gsub(/([&%$#_{}])/) { "\\#{Regexp.last_match(1)}" }
  s = s.gsub('~', '\\textasciitilde{}').gsub('^', '\\textasciicircum{}')
  s.gsub("\x00", '\\textbackslash{}')
end

# escape text but keep URLs clickable
def esc_url(s)
  s.to_s.split(%r{(https?://[^\s,)]+)}).map do |part|
    part =~ %r{\Ahttps?://} ? "\\url{#{part}}" : esc(part)
  end.join
end

MONTHS = {}
%w[jan feb mar apr may jun jul aug sep oct nov dec].each_with_index { |m, i| MONTHS[m] = i + 1 }

# "May 2026" / "Fall 2020" / "Spring 2024" / "2026.05" / "2026.05–Present" -> Date
def parse_when(s)
  s = s.to_s
  if s =~ /(\d{4})\.(\d{1,2})/
    Date.new(Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, 1)
  elsif s =~ /Fall\s+(\d{4})/i
    Date.new(Regexp.last_match(1).to_i, 9, 1)
  elsif s =~ /Spring\s+(\d{4})/i
    Date.new(Regexp.last_match(1).to_i, 3, 1)
  elsif s =~ /([A-Za-z]+)\s+(\d{4})/ && MONTHS[Regexp.last_match(1).downcase[0, 3]]
    Date.new(Regexp.last_match(2).to_i, MONTHS[Regexp.last_match(1).downcase[0, 3]], 1)
  elsif s =~ /(\d{4})/
    Date.new(Regexp.last_match(1).to_i, 1, 1)
  else
    Date.new(1900, 1, 1)
  end
end

def to_date(v)
  case v
  when Date then v
  when String then parse_when(v)
  else Date.new(1900, 1, 1)
  end
end

# ------------------------------------------------------------ parse cv.md ---
sections = {}
current = nil
lines = cvmd.lines
lines.each_with_index do |line, i|
  if lines[i + 1] && lines[i + 1] =~ /\A=+\s*\z/
    current = line.strip
    sections[current] = []
  elsif line =~ /\A=+\s*\z/
    next
  elsif current
    sections[current] << line.rstrip
  end
end

education = sections.fetch('Education', []).grep(/\A\* /).map { |l| l.sub(/\A\* /, '') }

# work experience: "* 2026.05–Present: Postdoctoral Researcher" + indented org
work = []
sections.fetch('Work experience', []).each do |l|
  if l =~ /\A\* (.+?):\s*(.+)\z/
    work << { 'label' => Regexp.last_match(1), 'title' => Regexp.last_match(2), 'detail' => nil }
  elsif l =~ /\A\s+\* (.+)\z/ && work.last
    work.last['detail'] = [work.last['detail'], Regexp.last_match(1)].compact.join('; ')
  end
end

# honors: "* **May 2026** — text"
honors = []
sections.fetch('Honors and Awards (Selected)', []).each do |l|
  next unless l =~ /\A\* \*\*(.+?)\*\*\s*[—–-]+\s*(.+)\z/
  honors << { 'date' => Regexp.last_match(1), 'text' => Regexp.last_match(2) }
end

# --------------------------------------------------------- assemble data ----
# D. Professional Experience: KATUSA + TA terms + postdoc positions, oldest first
experience = []
(extra['experience'] || []).each do |e|
  experience << { sort: to_date(e['sort']), label: e['date'],
                  body: "\\textbf{#{esc(e['title'])}} #{esc(e['detail'])}" }
end
teaching.each do |t|
  courses = (t['courses'] || []).map { |c| "\\newline \\hspace*{1.5em}-- #{esc(c)}" }.join
  experience << { sort: to_date(t['date']), label: t['term'],
                  body: "\\textbf{#{esc(t['role'])}.} #{esc(t['venue'])}#{courses}" }
end
work.each do |w|
  experience << { sort: parse_when(w['label']), label: w['label'],
                  body: "\\textbf{#{esc(w['title'])}.} #{esc(w['detail'])}" }
end
experience.sort_by! { |e| e[:sort] }

# E. Honors and Awards: selected awards + full scholarship list, newest first
honor_rows = honors.map { |h| { sort: parse_when(h['date']), label: h['date'], body: esc(h['text']) } }
(extra['scholarships'] || []).each do |s|
  honor_rows << { sort: to_date(s['sort']), label: s['date'], body: esc(s['text']) }
end
honor_rows = honor_rows.sort_by { |h| h[:sort] }.reverse

# F. Publications
by_cat = Hash.new { |h, k| h[k] = [] }
pubs.each { |p| by_cat[p['category']] << p }
%w[manuscripts underreview conferences thesis].each { |c| by_cat[c].sort_by! { |p| p['date'].to_s } }

journals  = by_cat['manuscripts'] + by_cat['underreview'] # published first, then under review
conf_intl = by_cat['conferences'].select { |p| p['scope'] == 'international' }
conf_dom  = by_cat['conferences'].select { |p| p['scope'] == 'domestic' }
untagged  = by_cat['conferences'].reject { |p| %w[international domestic].include?(p['scope']) }
warn "WARNING: #{untagged.size} conference entries lack a scope tag and were EXCLUDED" unless untagged.empty?

def pub_body(p)
  body = esc(p['citation'])
  body += " (#{esc(p['presentation'])})" if p['presentation']
  body += " \\url{#{p['paperurl']}}" if p['paperurl'] && %w[manuscripts thesis].include?(p['category'])
  body += " \\textbf{#{esc(p['note'])}}" if p['note']
  body
end

# ------------------------------------------------------------- LaTeX out ----
p_ = extra['personal']
updated = Time.now.strftime('%-d, %B, %Y')
header_name = 'Jeon, Jaehwan' # header format follows the original PDF

tex = String.new
tex << <<~'PREAMBLE'
  % GENERATED by scripts/build_cv_pdf.rb — DO NOT EDIT. Run scripts/build_cv_pdf.sh.
  \documentclass[11pt]{article}
  \usepackage[margin=1in]{geometry}
  \usepackage{newtxtext,newtxmath}
  \usepackage{graphicx}
  \usepackage{longtable}
  \usepackage{titlesec}
  \usepackage{fancyhdr}
  \usepackage[colorlinks=true,urlcolor=blue,linkcolor=black]{hyperref}
  \urlstyle{same}
  \setlength{\parindent}{0pt}
  \renewcommand{\thesection}{\Alph{section}.}
  \titleformat{\section}{\LARGE\bfseries}{\thesection}{0.4em}{}[{\vspace{2pt}\titlerule[1.4pt]}]
  \titlespacing*{\section}{0pt}{16pt}{10pt}
  \renewcommand{\thesubsection}{\Alph{section}.\arabic{subsection}}
  \titleformat{\subsection}{\large\bfseries}{\thesubsection}{0.4em}{}
  \titlespacing*{\subsection}{0pt}{12pt}{6pt}
  \pagestyle{fancy}
  \fancyhf{}
  \renewcommand{\headrulewidth}{0pt}
  % dated rows:  <date label> <body>
  \newenvironment{datedlist}
    {\begin{longtable}{@{}p{3.1cm}@{\hspace{0.5cm}}p{\dimexpr\textwidth-3.6cm\relax}@{}}}
    {\end{longtable}}
  % numbered rows:  <J1.> <citation>
  \newenvironment{publist}
    {\begin{longtable}{@{}p{1.4cm}@{\hspace{0.4cm}}p{\dimexpr\textwidth-1.8cm\relax}@{}}}
    {\end{longtable}}
PREAMBLE

tex << "\\fancyhead[L]{\\small #{header_name} -- CV, updated #{updated}}\n"
tex << "\\begin{document}\n\n"

# ----- title page
name_line = esc(p_['name'].to_s.sub(/,\s*Ph\.D\.\z/, ''))
tex << "\\thispagestyle{fancy}\n\\vspace*{5cm}\n\\begin{center}\n"
tex << "{\\LARGE #{name_line}, Ph.D.\\\\[6pt]\n"
tex << (p_['affiliation_lines'] || []).map { |l| esc(l) }.join("\\\\[6pt]\n")
tex << "}\\\\[3cm]\n{\\Huge \\textbf{Curriculum Vitae}}\n\\end{center}\n\\clearpage\n\n"

# ----- A. Personal
photo = p_['photo'] ? 'photo.jpg' : nil
tex << "\\section{Personal}\n"
tex << "\\begin{minipage}[t]{#{photo ? '0.70' : '1.0'}\\textwidth}\n\\vspace{0pt}\n"
tex << "\\begin{tabular}{@{}p{3.1cm}@{\\hspace{0.3cm}}p{\\dimexpr\\linewidth-3.4cm\\relax}@{}}\n"
tex << "\\textbf{Date of Birth} & #{esc(p_['date_of_birth'])} \\\\\n" if p_['date_of_birth']
tex << "\\textbf{Citizenship} & #{esc(p_['citizenship'])} \\\\\n" if p_['citizenship']
(p_['addresses'] || []).each_with_index do |a, i|
  label = i.zero? ? '\\textbf{Addresses}' : ''
  tex << "#{label} & #{esc(a['label'])}: #{esc(a['text'])} \\\\\n"
end
tex << "\\textbf{E-mail Address} & \\href{mailto:#{p_['email']}}{#{esc(p_['email'])}} \\\\\n" if p_['email']
tex << "\\textbf{Homepage} & \\url{#{p_['website']}} \\\\\n" if p_['website']
tex << "\\textbf{Current Rank} & #{esc(p_['current_rank'])} \\\\\n" if p_['current_rank']
tex << "\\end{tabular}\n\\end{minipage}"
if photo
  tex << "\\hfill\n\\begin{minipage}[t]{0.22\\textwidth}\n\\vspace{0pt}\n" \
         "\\includegraphics[width=\\linewidth]{#{photo}}\n\\end{minipage}"
end
tex << "\n\n"

# ----- B. University Education
tex << "\\section{University Education}\n"
education.each do |e|
  text = esc(e).sub(/\A([^,]+,)/) { "\\textbf{#{Regexp.last_match(1)}}" }
  tex << "#{text}\\\\[3pt]\n"
end
tex << "\n"

# ----- C. Research Interest
tex << "\\section{Research Interest}\n#{esc(extra['research_interests'])}\n\n"

# ----- D. Professional Experience
tex << "\\section{Professional Experience}\n\\begin{datedlist}\n"
experience.each { |e| tex << "#{esc(e[:label])} & #{e[:body]} \\\\[3pt]\n" }
tex << "\\end{datedlist}\n\n"

# ----- E. Honors and Awards
tex << "\\section{Honors and Awards}\n\\begin{datedlist}\n"
honor_rows.each { |h| tex << "#{esc(h[:label])} & #{h[:body]} \\\\[3pt]\n" }
tex << "\\end{datedlist}\n\n"

# ----- F. Publications
tex << "\\section{Publications}\n"
unless by_cat['thesis'].empty?
  tex << "\\subsection{Ph.D. Dissertation}\n\\begin{publist}\n"
  by_cat['thesis'].each_with_index { |p, i| tex << "T#{i + 1}. & #{pub_body(p)} \\\\[3pt]\n" }
  tex << "\\end{publist}\n"
end
tex << "\\subsection{Journal Publications}\n\\begin{publist}\n"
journals.each_with_index { |p, i| tex << "J#{i + 1}. & #{pub_body(p)} \\\\[3pt]\n" }
tex << "\\end{publist}\n"
tex << "\\subsection{Conferences (International)}\n\\begin{publist}\n"
conf_intl.each_with_index { |p, i| tex << "C-I#{i + 1}. & #{pub_body(p)} \\\\[3pt]\n" }
tex << "\\end{publist}\n"
tex << "\\subsection{Conferences (Domestic -- South Korea)}\n\\begin{publist}\n"
conf_dom.each_with_index { |p, i| tex << "C-D#{i + 1}. & #{pub_body(p)} \\\\[3pt]\n" }
tex << "\\end{publist}\n\n"

# ----- G. Patents
unless (extra['patents'] || []).empty?
  tex << "\\section{Patents}\n\\begin{publist}\n"
  extra['patents'].each_with_index { |p, i| tex << "G#{i + 1}. & #{esc_url(p)} \\\\[3pt]\n" }
  tex << "\\end{publist}\n\n"
end

# ----- H. Open-Source Software Contributions
unless (extra['open_source'] || []).empty?
  tex << "\\section{Open-Source Software Contributions}\n\\begin{publist}\n"
  extra['open_source'].each_with_index { |o, i| tex << "H#{i + 1}. & #{esc_url(o['text'])} \\\\[3pt]\n" }
  tex << "\\end{publist}\n\n"
end

# ----- I. Invited Talks and Seminars
unless talks.empty?
  tex << "\\section{Invited Talks and Seminars}\n\\begin{publist}\n"
  talks.sort_by { |t| to_date(t['date']) }.each_with_index do |t, i|
    date_str = to_date(t['date']).strftime('%B %-d, %Y')
    body = "#{esc(t['title'])}. \\textit{#{esc(t['type'])}}, #{esc(t['venue'])}"
    body += ", #{esc(t['location'])}" if t['location']
    body += ". #{date_str}."
    tex << "S#{i + 1}. & #{body} \\\\[3pt]\n"
  end
  tex << "\\end{publist}\n\n"
end

tex << "\\end{document}\n"

FileUtils.mkdir_p(File.dirname(OUT))
File.write(OUT, tex)
puts "Wrote #{OUT} (#{journals.size} journal, #{conf_intl.size} intl conf, #{conf_dom.size} domestic conf, #{talks.size} talks)"
