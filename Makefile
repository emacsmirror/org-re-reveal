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

TOP          := $(dir $(lastword $(MAKEFILE_LIST)))

UUID         := $(shell type uuidgen > /dev/null 2>&1 && uuidgen | cut -c -7)

UBUNTU_EMACS := 24.4 24.5
ALPINE_EMACS := 25.3 26.2
DOCKER_EMACS := $(UBUNTU_EMACS:%=ubuntu-min-%) $(ALPINE_EMACS:%=alpine-min-%)

DEPENDS      := org-plus-contrib htmlize
ADDITON      := test-cases

EMACS        ?= emacs
BATCH        := $(EMACS) -Q --batch -L ./ $(DEPENDS:%=-L ./%/)

TESTFILE     := org-re-reveal-tests.el
ELS          := org-re-reveal.el ox-re-reveal.el

CORTELS      := $(TESTFILE) cort-test.el

REVEALTEST   := blockquote extra-scripts highlightjs internal-links klipsify klipsify-python merge-classes multiplex noslide options pdf-notes plugins reveal-toc revealjs4 src-blocks-hl src-blocks-no-hl slide-numbers slide-numbers-toc slide-numbers-reveal-toc split title-slide title-slide-notes

##################################################

.PHONY: all build diff check allcheck test clean clean-soft

all: build

##############################

build: $(ELS:%.el=%.elc)

%.elc: %.el $(DEPENDS)
	$(BATCH) -f batch-byte-compile $<

##############################
#
#  one-time test (on top level)
#

check: build
	$(BATCH) -l $(TESTFILE) -f cort-test-run

diff:
	echo $(REVEALTEST) | xargs -n1 -t -I% bash -c "cd test-cases; diff -u expect-%.html test-%.html"

##############################
#
#  multi Emacs version test (on independent environment)
#

allcheck: $(DOCKER_EMACS:%=.make/verbose-${UUID}-emacs-test--%)
	@echo ""
	@cat $^ | grep =====
	@rm -rf $^

.make/verbose-%: .make $(DEPENDS)
	docker run -itd --name $* conao3/emacs:$(shell echo $* | sed "s/.*--//") /bin/sh
	docker cp . $*:/test
	docker exec $* sh -c "cd test && make clean-soft && make check -j 2>&1" | tee $@
	docker rm -f $*

##############################
#
#  silent `allcheck' job
#

test: $(DOCKER_EMACS:%=.make/silent-${UUID}-emacs-test--%)
	@echo ""
	@cat $^ | grep =====
	@rm -rf $^

.make/silent-%: .make $(DEPENDS)
	docker run -itd --name $* conao3/emacs:$(shell echo $* | sed "s/.*--//") /bin/sh
	docker cp . $*:/test
	docker exec $* sh -c "cd test && make clean-soft && make check -j 2>&1" > $@ || ( docker rm -f $*; cat $@ || false )
	docker rm -f $*

.make:
	mkdir $@

##############################
#
#  other make jobs
#

clean-soft:
	rm -rf $(ELS:%.el=%.elc) .make

clean:
	rm -rf $(ELS:%.el=%.elc) $(DEPENDS) .make

##############################
#
#  depend files
#

# This is Org mode 9.4 including that fix:
# https://lists.gnu.org/archive/html/emacs-orgmode/2020-09/msg00763.html
org-plus-contrib:
	curl -L https://orgmode.org/elpa/org-plus-contrib-20200921.tar > $@.tar
	mkdir $@ && tar xf $@.tar -C $@ --strip-components 1
	rm -rf $@.tar

htmlize:
	curl -L https://github.com/hniksic/emacs-htmlize/archive/master.tar.gz > $@.tar.gz
	mkdir $@ && tar xf $@.tar.gz -C $@ --strip-components 1
	rm -rf $@.tar.gz
