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

##################################################

all: build

##############################

build: $(ELS:%.el=%.elc)

##############################

%.elc: %.el $(PACKAGES)
	$(BATCH) $(DEPENDS:%=-L %/) -f batch-byte-compile $<

test: build
	$(BATCH) $(DEPENDS:%=-L %/) -l $(TESTFILE) -f cort-run-tests

org-plus-contrib:
        curl -O https://orgmode.org/elpa/org-plus-contrib-$(ORG_VER).tar
	tar xf org-plus-contrib-$(ORG_VER).tar
	mv org-plus-contrib-$(ORG_VER) org-plus-contrib

htmlize:
	git clone --depth=1 https://github.com/hniksic/emacs-htmlize.git $@
