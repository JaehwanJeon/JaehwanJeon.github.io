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
* Ph.D in Version Control Theory, GitHub University, 2018 (expected)
* M.S. in Jekyll, GitHub University, 2014
* B.S. in GitHub, GitHub University, 2012

Work experience
======
* Spring 2024: Academic Pages Collaborator
  * GitHub University
  * Duties includes: Updates and improvements to template
  * Supervisor: The Users

* Fall 2015: Research Assistant
  * GitHub University
  * Duties included: Merging pull requests
  * Supervisor: Professor Hub

* Summer 2015: Research Assistant
  * GitHub University
  * Duties included: Tagging issues
  * Supervisor: Professor Git
  
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
  {% for category in site.publication_category %}
    {% if category[0] == 'conferences' %}{% continue %}{% endif %}
    {% assign pubs = site.data.publications | where: "category", category[0] %}
    {% if pubs.size > 0 %}
      <h3>{{ category[1].title }}</h3>
      <ul>{% for p in pubs %}
        <li><div class="archive__item"><h3 class="archive__item-title">{{ p.title }}</h3>{% if p.citation %}<p class="archive__item-excerpt">{{ p.citation }}</p>{% endif %}</div></li>
      {% endfor %}</ul>
    {% endif %}
  {% endfor %}
  
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
