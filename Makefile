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

##############################

%.elc: %.el $(PACKAGES)
	$(BATCH) $(DEPENDS:%=-L %/) -f batch-byte-compile $<

test: build
	$(BATCH) $(DEPENDS:%=-L %/) -l $(TESTFILE) -f cort-run-tests

diff:
	echo $(REVEALTEST) | xargs -n1 -t -I% bash -c "cd test-cases; diff -u expect-%.html test-%.html"

org-plus-contrib:
	curl -O https://orgmode.org/elpa/org-plus-contrib-$(ORG_VER).tar > $@.tar
	mkdir $@ && tar xf $@.tar -C $@ --strip-components 1

htmlize:
	curl -O https://github.com/hniksic/emacs-htmlize/archive/master.tar.gz > $@.tar.gz
	mkdir $@ && tar xf $@.tar.gz -C $@ --strip-components 1
