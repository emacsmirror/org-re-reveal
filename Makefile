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
EMACS_RAW    := $(sort $(shell compgen -c emacs- | xargs))
EXPECT_EMACS  += 24.4 24.5
EXPECT_EMACS  += 25.1 25.2 25.3
EXPECT_EMACS  += 26.1 26.2

ALL_EMACS    := $(filter $(EMACS_RAW),$(EXPECT_EMACS:%=emacs-%))

DEPENDS     := org-plus-contrib htmlize
ADDITON     := test-cases

EMACS       ?= emacs
BATCHARGS   := -Q --batch -L ./ $(DEPENDS:%=-L ./%/)

TESTFILE    := org-re-reveal-tests.el
ELS         := org-re-reveal.el ox-re-reveal.el

REVEALTEST  := highlightjs klipsify slide-numbers slide-numbers-toc split

##################################################

.PHONY: all build diff check allcheck test clean

all: build

##############################

build: $(ELS:%.el=%.elc)

%.elc: %.el $(DEPENDS)
	$(BATCH) $(DEPENDS:%=-L %/) -f batch-byte-compile $<

##############################
#
#  one-time test (on top level)
#

check: build
	$(EMACS) $(BATCHARGS) -l $(TESTFILE) -f cort-test-run

diff:
	echo $(REVEALTEST) | xargs -n1 -t -I% bash -c "cd test-cases; diff -u expect-%.html test-%.html"

##############################
#
#  multi Emacs version test (on independent environment)
#

allcheck: $(ALL_EMACS:%=.make/verbose-%)
	@echo ""
	@cat $(^:%=%/.make-test-log) | grep =====
	@rm -rf $^

.make/verbose-%: $(DEPENDS)
	mkdir -p $@
	cp -rf $(ELS) $(CORTELS) $(DEPENDS) $(ADDITON) $@/
	cd $@; echo $(ELS) | xargs -n1 -t $* $(BATCHARGS) -f batch-byte-compile
	cd $@; $* $(BATCHARGS) -l $(TESTFILE) -f cort-test-run | tee .make-test-log

##############################
#
#  silent `allcheck' job
#

test: $(ALL_EMACS:%=.make/silent-%)
	@echo ""
	@cat $(^:%=%/.make-test-log) | grep =====
	@rm -rf $^

.make/silent-%: $(DEPENDS)
	@mkdir -p $@
	@cp -rf $(ELS) $(CORTELS) $(DEPENDS) $(ADDITON) $@/
	@cd $@; echo $(ELS) | xargs -n1 $* $(BATCHARGS) -f batch-byte-compile
	@cd $@; $* $(BATCHARGS) -l $(TESTFILE) -f cort-test-run > .make-test-log 2>&1

##############################
#
#  other make jobs
#

clean:
	rm -rf $(ELC) $(DEPENDS) .make

##############################
#
#  depend files
#

org-plus-contrib:
	curl -L https://orgmode.org/elpa/org-plus-contrib-20190422.tar > $@.tar
	mkdir $@ && tar xf $@.tar -C $@ --strip-components 1
	rm -rf $@.tar

htmlize:
	curl -L https://github.com/hniksic/emacs-htmlize/archive/master.tar.gz > $@.tar.gz
	mkdir $@ && tar xf $@.tar.gz -C $@ --strip-components 1
	rm -rf $@.tar.gz
