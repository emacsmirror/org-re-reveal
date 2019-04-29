## Makefile

# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2019      Naoya Yamashita <conao3@gmail.com>

# This file is not part of GNU Emacs.

## License:
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with GNU Emacs; see the file COPYING.
# If not, see http://www.gnu.org/licenses/ or write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.

all:

# org-re-reveal requires ((emacs "24.4") (org "8.3") (htmlize "1.34"))

TOP         := $(dir $(lastword $(MAKEFILE_LIST)))

EMACS       ?= emacs
BATCH       := $(EMACS) -Q --batch -L $(TOP)

PACKAGES    := org-plus-contrib htmlize

ORG         := org-plus-contrib
HTMLIZE     := htmlize
DEPENDS     := $(ORG) $(HTMLIZE)

ORG_VER     := 20190422

TESTFILE    := org-re-reveal-tests.el
ELS         := org-re-reveal.el ox-re-reveal.el

REVEALTEST  := highlightjs klipsify slide-numbers split

##################################################

all: build

##############################

build: $(ELS:%.el=%.elc)

test: build
	$(BATCH) $(DEPENDS:%=-L %/) -l $(TESTFILE) -f cort-test-run

diff:
	echo $(REVEALTEST) | xargs -n1 -t -I% bash -c "cd test-cases; diff -u expect-%.html test-%.html"

##############################

%.elc: %.el $(PACKAGES)
	$(BATCH) $(DEPENDS:%=-L %/) -f batch-byte-compile $<

org-plus-contrib:
	curl -L https://orgmode.org/elpa/org-plus-contrib-$(ORG_VER).tar > $@.tar
	mkdir $@ && tar xf $@.tar -C $@ --strip-components 1

htmlize:
	curl -L https://github.com/hniksic/emacs-htmlize/archive/master.tar.gz > $@.tar.gz
	mkdir $@ && tar xf $@.tar.gz -C $@ --strip-components 1
