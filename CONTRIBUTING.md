<!--- Local IspellDict: en -->
<!-- Copyright (C) 2019 Jens Lechtenbörger -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

Your contributions in the form of issues, patches, or merge/pull
requests are very welcome!

If you open an issue, please include version information for Emacs
(`M-x emacs-version`), Org mode (`M-x org-version`), and org-re-reveal
(`M-x org-re-reveal-version`).

Note that this project with all its contents is published under the
GNU General Public License, version 3 or later.  Thus, when submitting
a contribution you agree that your work is published under that same
license.  Also, when submitting contributions you assert that you hold
the necessary rights (which typically means that the contribution is
your original piece of work, but not something belonging to, say, your
employer or to some other author).

At least in Germany, copyright always remains with the author.
However, the amount of work that is necessary for copyright laws to be
applicable is not clearly defined.  Thus, I suggest that with
non-trivial contributions you include a line as follows:

```
;; Copyright (C) <year> <your name> <your e-mail address if you like>
```

Please discuss larger changes first to avoid work that might not be
integrated later on.

[This document](https://github.com/NARKOZ/gitlab/blob/master/CONTRIBUTING.md#pull-requests)
explains how create merge/pull requests based on topic branches, which
is also recommended for larger contributions here.  Smaller changes
might also be performed using the buttons `edit` or `Web IDE` when
viewing a file of your fork in GitLab’s Web interface.

Please make sure that your merge requests pass tests (`make check`,
maybe also `make allcheck` which sets up Docker images first).
Depending on the nature of your changes, you may need to update the
files `test-cases/expect-*`.
