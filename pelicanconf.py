#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Will Hopper'
SITENAME = 'Will Hopper'
SITESUBTITLE = 'Cognitive Psychology, Modeling, and Coding'
SITEURL = 'http://people.umass.edu/whopper'

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

DEFAULT_PAGINATION = 5
SUMMARY_MAX_LENGTH = 90
DIRECT_TEMPLATES = ('index', 'posts_index', 'tags', 'archives')
PAGINATED_DIRECT_TEMPLATES = ['posts_index']

POSTS_PATHS = ['posts']
POSTS_URL = 'posts/'
POSTS_INDEX_SAVE_AS = 'posts/index.html'

ARTICLE_URL = 'posts/{slug}/'
ARTICLE_SAVE_AS = 'posts/{slug}/index.html'

AUTHOR_SAVE_AS = False
CATEGORY_SAVE_AS = False

RELATIVE_URLS = False
