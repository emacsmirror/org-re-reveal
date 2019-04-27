all:

# org-re-reveal requires ((emacs "24.4") (org "8.3") (htmlize "1.34"))

TOP         := $(dir $(lastword $(MAKEFILE_LIST)))

EMACS       ?= emacs
BATCH       := $(EMACS) -Q --batch -L $(TOP)

PACKAGES    := org-mode htmlize

ORG         := org-mode/lisp org-mode/contrib/lisp
HTMLIZE     := htmlize
DEPENDS     := $(ORG) $(HTMLIZE)

TESTFILE    := org-re-reveal-tests.el
ELS         := org-re-reveal.el ox-re-reveal.el

##################################################

all: build

##############################

build: $(ELS:%.el=%.elc)

##############################

ox-re-reveal.elc: ox-re-reveal.el
	$(BATCH) -f batch-byte-compile $<

%.elc: %.el $(PACKAGES)
	$(BATCH) $(DEPENDS:%=-L %/) -f batch-byte-compile $<

org-mode:
	git clone --depth=1 https://code.orgmode.org/bzg/org-mode.git $@
	$(MAKE) EMACS=$(EMACS) compile -C $@

htmlize:
	git clone --depth=1 https://github.com/hniksic/emacs-htmlize.git $@
