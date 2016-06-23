#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Will Hopper'
SITENAME = 'Will Hopper'
SITESUBTITLE = 'Cognitive Psychology, Modeling, and Coding'
SITEURL = 'http://people.umass.edu/whopper/'

PATH = 'content'
STATIC_PATHS = ['img','pres','pub', 'misc']

TIMEZONE = 'America/New_York'
DEFAULT_LANG = 'en'
DEFAULT_DATE = 'fs'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

THEME = 'academia'
AVATAR = 'will-web.jpg'

# Links widget
LINKS = (('cv', 'misc/CV.pdf'),
         ('email', 'mailto:whopper@psych.umass.edu'),
         ('github', 'https://github.com/wjhopper'))

DEFAULT_PAGINATION = False

TAGS_SAVE_AS = ''
AUTHORS_SAVE_AS = ''
ARCHIVES_SAVE_AS = ''
CATEGORIES_SAVE_AS = ''

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True
