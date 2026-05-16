---
layout: archive
title: "CV"
permalink: /cv/
author_profile: true
redirect_from:
  - /resume
---

{% include base_path %}

Education
======
* M.S./Ph.D. in Civil and Environmental Engineering, Seoul National University, 2020.03 – 2026.02
* Visiting Graduate Student, University of Toronto, Toronto, Canada, September 1, 2022 – February 16, 2023
* B.S. in Civil and Environmental Engineering, Seoul National University, 2013.03 – 2020.02

Work experience
======
* 2026.05–Present: Postdoctoral Researcher
  * Department of Civil and Mineral Engineering, University of Toronto

* 2026.03–2026.04: Postdoctoral Researcher
  * Institute of Construction and Environmental Engineering, Seoul National University

Honors and Awards (Selected)
======
* **Nov 2025** — Computational Structural Engineering Institute of Korea (COSEIK) Annual Conference Best Paper Presentation Award
* **May 2025** — International Conference on Structural Safety and Reliability (ICOSSAR'25) Award Finalist
* **Oct 2024** — Korean Society of Civil Engineers (KSCE 2024) Convention Best Paper Award
* **May 2024** — Engineering Mechanics Institute (EMI) – Probabilistic Methods Committee (PMC) Award Finalist
* **June 2022** — Mitacs Globalink Research Award (3,000 CAD ($2,800)), Mitacs, Canada

Skills
======
* Skill 1
* Skill 2
  * Sub-skill 2.1
  * Sub-skill 2.2
  * Sub-skill 2.3
* Skill 3

Publications
======
{% for category in site.publication_category %}{% if category[0] == 'conferences' %}{% continue %}{% endif %}{% assign pubs = site.data.publications | where: "category", category[0] %}{% if pubs.size > 0 %}
<h3>{{ category[1].title }}</h3>
<ul>{% for p in pubs %}
<li><div class="archive__item"><h4 class="archive__item-title">{{ p.title }}</h4>{% if p.citation %}<p class="archive__item-excerpt">{{ p.citation }}</p>{% endif %}</div></li>{% endfor %}</ul>
{% endif %}{% endfor %}
  
Talks
======
  <ul>{% for post in site.talks reversed %}
    {% include archive-single-talk-cv.html  %}
  {% endfor %}</ul>
  
Teaching
======
  <ul>{% for t in site.data.teaching %}
    <li><div class="archive__item"><h3 class="archive__item-title">{{ t.role }} — {{ t.term }}</h3><p class="archive__item-excerpt">{{ t.venue }}{% for c in t.courses %}<br/>{{ c }}{% endfor %}</p></div></li>
  {% endfor %}</ul>
  
Service and leadership
======
* Currently signed in to 43 different slack teams
