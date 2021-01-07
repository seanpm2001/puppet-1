# This file is managed by puppet

# -*- python -*-

# Copyright (C) 1998,1999,2000 by the Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


"""This is the module which takes your site-specific settings.

From a raw distribution it should be copied to mm_cfg.py.  If you
already have an mm_cfg.py, be careful to add in only the new settings
you want.  The complete set of distributed defaults, with annotation,
are in ./Defaults.  In mm_cfg, override only those you want to
change, after the

  from Defaults import *

line (see below).

Note that these are just default settings - many can be overridden via the
admin and user interfaces on a per-list or per-user basis.

Note also that some of the settings are resolved against the active list
setting by using the value as a format string against the
list-instance-object's dictionary - see the distributed value of
DEFAULT_MSG_FOOTER for an example."""


#######################################################
#    Here's where we get the distributed defaults.    #

from Defaults import *  # noqa

##############################################################
# Put YOUR site-specific configuration below, in mm_cfg.py . #
# See Defaults.py for explanations of the values.            #

# The name of the list Mailman uses to send password reminders
# and similar. Don't change if you want mailman-owner to be
# a valid local part.
MAILMAN_SITE_LIST = 'mailman'

# If you change these, you have to configure your http server
# accordingly (Alias and ScriptAlias directives in most httpds)
DEFAULT_URL_PATTERN = 'https://%s/mailman/'
PRIVATE_ARCHIVE_URL = '/mailman/private'
IMAGE_LOGOS = '/images/mailman/'

# Default domain for email addresses of newly created MLs
DEFAULT_EMAIL_HOST = 'lists.wikimedia.org'
# Default host for web interface of newly created MLs
DEFAULT_URL_HOST = 'lists.wikimedia.org'
# Required when setting any of its arguments.
add_virtualhost(DEFAULT_URL_HOST, DEFAULT_EMAIL_HOST)

# The default language for this server.
DEFAULT_SERVER_LANGUAGE = 'en'

# Iirc this was used in pre 2.1, leave it for now
USE_ENVELOPE_SENDER = 0              # Still used?

# Unset send_reminders on newly created lists
DEFAULT_SEND_REMINDERS = 0

# Uncomment this if you configured your MTA such that it
# automatically recognizes newly created lists.
# (see /usr/share/doc/mailman/README.{EXIM,...})
# MTA=None   # Misnomer, suppresses alias output on newlist
MTA = None

# If SpamAssassin has run before the message is received by mailman, reject
# at least the most egregious spam identified. Further tailoring per list:
# https://wikitech.wikimedia.org/wiki/Mailman#Spam_scores
DEFAULT_BOUNCE_MATCHING_HEADERS = """
X-Spam-Score:[^+]*[+]{6,}
"""

# Uncomment if you use Postfix virtual domains, but be sure to
# read /usr/share/doc/mailman/README.POSTFIX first.
# MTA='Postfix'

# Uncomment if you want to filter mail with SpamAssassin. For
# more information please visit this website:
# http://www.daa.com.au/~james/articles/mailman-spamassassin/
# GLOBAL_PIPELINE.insert(1, 'SpamAssassin')

# Note - if you're looking for something that is imported from mm_cfg, but you
# didn't find it above, it's probably in /usr/lib/mailman/Mailman/Defaults.py.

# Set Reply-To to the list by default
DEFAULT_REPLY_GOES_TO_LIST = 1

# Htdig integration
# HTDIG_RUNDIG_PATH = "/usr/bin/rundig"
# HTDIG_HTSEARCH_PATH = "/usr/lib/cgi-bin/htsearch"
# USE_HTDIG = 1

# Customization
SHORTCUT_ICON = 'favicon.png'

# Limiting the size of message to prevent archrunner from dying...
MAX_MESSAGE_SIZE = 5120

# we put footers etc. and hence invalidate DKIM signatures
# although they shouldn't theoretically hurt, remove them to avoid confusion
REMOVE_DKIM_HEADERS = Yes

# use https for mailman archive links instead of the default http
PUBLIC_ARCHIVE_URL = 'https://%(hostname)s/pipermail/%(listname)s/'

# Don't store messages in qfiles/bad
QRUNNER_SAVE_BAD_MESSAGES = No

# Expire cookies 3600 seconds (1 hour) after last use
AUTHENTICATION_COOKIE_LIFETIME = 3600

# Don't include full email in automatic bounces
RESPONSE_INCLUDE_LEVEL = 0

# set a secret to be included in HTML subscription forms to help
# with bots subscription
SUBSCRIBE_FORM_SECRET = open('/etc/machine-id', 'r').readline().rstrip()

# Default action for posts whose From: address domain has a DMARC policy of
# reject or quarantine.  See DEFAULT_FROM_IS_LIST below.  Whatever is set as
# the default here precludes the list owner from setting a lower value.
# 0 = Accept
# 1 = Munge From
# 2 = Wrap Message
# 3 = Reject
# 4 = Discard
DEFAULT_DMARC_MODERATION_ACTION = 1

DEFAULT_CHARSET = 'utf-8'
VERBATIM_ENCODING = ['iso-2022-jp', 'utf-8']
LC_DESCRIPTIONS['ar'] = ('Arabic', 'utf-8', 'rtl')
LC_DESCRIPTIONS['ast'] = ('Asturian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['ca'] = ('Catalan', 'utf-8', 'ltr')
LC_DESCRIPTIONS['cs'] = ('Czech', 'iso-8859-2', 'ltr')
LC_DESCRIPTIONS['da'] = ('Danish', 'utf-8', 'ltr')
LC_DESCRIPTIONS['de'] = ('German', 'utf-8', 'ltr')
LC_DESCRIPTIONS['en'] = ('English', 'utf-8', 'ltr')
LC_DESCRIPTIONS['eo'] = ('Esperanto', 'utf-8', 'ltr')
LC_DESCRIPTIONS['es'] = ('Spanish', 'utf-8', 'ltr')
LC_DESCRIPTIONS['et'] = ('Estonian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['eu'] = ('Euskara', 'utf-8', 'ltr') # Basque
LC_DESCRIPTIONS['fa'] = ('Persian', 'utf-8', 'rtl')
LC_DESCRIPTIONS['fi'] = ('Finnish', 'utf-8', 'ltr')
LC_DESCRIPTIONS['fr'] = ('French', 'utf-8', 'ltr')
LC_DESCRIPTIONS['gl'] = ('Galician', 'utf-8', 'ltr')
LC_DESCRIPTIONS['el'] = ('Greek', 'utf-8', 'ltr')
LC_DESCRIPTIONS['he'] = ('Hebrew', 'utf-8', 'rtl')
LC_DESCRIPTIONS['hr'] = ('Croatian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['hu'] = ('Hungarian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['ia'] = ('Interlingua', 'utf-8', 'ltr')
LC_DESCRIPTIONS['it'] = ('Italian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['ja'] = ('Japanese', 'utf-8', 'ltr')
LC_DESCRIPTIONS['ko'] = ('Korean', 'utf-8', 'ltr')
LC_DESCRIPTIONS['lt'] = ('Lithuanian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['nl'] = ('Dutch', 'utf-8', 'ltr')
LC_DESCRIPTIONS['no'] = ('Norwegian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['pl'] = ('Polish', 'utf-8', 'ltr')
LC_DESCRIPTIONS['pt'] = ('Portuguese', 'utf-8', 'ltr')
LC_DESCRIPTIONS['pt_BR'] = ('Portuguese (Brazil)', 'utf-8', 'ltr')
LC_DESCRIPTIONS['ro'] = ('Romanian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['ru'] = ('Russian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['sk'] = ('Slovak', 'utf-8', 'ltr')
LC_DESCRIPTIONS['sl'] = ('Slovenian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['sr'] = ('Serbian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['sv'] = ('Swedish', 'utf-8', 'ltr')
LC_DESCRIPTIONS['tr'] = ('Turkish', 'utf-8', 'ltr')
LC_DESCRIPTIONS['uk'] = ('Ukrainian', 'utf-8', 'ltr')
LC_DESCRIPTIONS['vi'] = ('Vietnamese', 'utf-8', 'ltr')
LC_DESCRIPTIONS['zh_CN'] = ('Chinese (China)', 'utf-8', 'ltr')
LC_DESCRIPTIONS['zh_TW'] = ('Chinese (Taiwan)', 'utf-8', 'ltr')

