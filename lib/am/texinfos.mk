## automake - create Makefile.in from Makefile.am

## Copyright (C) 1994-2012 Free Software Foundation, Inc.

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

# FIXME: this should probably be generalized and moved to header-vars.mk
am.texi.create-installdir = $(if $(and $1,$^),$(MKDIR_P) '$(DESTDIR)$1',@:)

# Avoid interferences from the environment.
ifeq ($(call am.vars.is-undef,info_TEXINFOS),yes)
  info_TEXINFOS :=
endif

## ---------- ##
## Building.  ##
## ---------- ##

.PHONY: dvi dvi-am html html-am info info-am pdf pdf-am ps ps-am
ifdef SUBDIRS
RECURSIVE_TARGETS += dvi-recursive html-recursive info-recursive
RECURSIVE_TARGETS += pdf-recursive ps-recursive
dvi: dvi-recursive
html: html-recursive
info: info-recursive
pdf: pdf-recursive
ps: ps-recursive
else
dvi: dvi-am
html: html-am
info: info-am
pdf: pdf-am
ps: ps-am
endif

ifdef info_TEXINFOS
dvi-am: $(DVIS)
html-am: $(HTMLS)
info-am: $(INFO_DEPS)
pdf-am: $(PDFS)
ps-am: $(PSS)
else
dvi-am:
html-am:
info-am:
pdf-am:
ps-am:
endif


## ------------ ##
## Installing.  ##
## ------------ ##

## Some code should be run only if install-info actually exists, and
## if the user doesn't request it not to be run (through the
## 'AM_UPDATE_INFO_DIR' environment variable).  See automake bug#9773
## and Debian Bug#543992.
am.texi.can-run-installinfo = \
  case $$AM_UPDATE_INFO_DIR in \
    n|no|NO) false;; \
    *) (install-info --version) >/dev/null 2>&1;; \
  esac

## Look in both . and srcdir because the info pages might have been
## rebuilt in the build directory.  Can't cd to srcdir; that might
## break a possible install-sh reference.
##
## Funny name due to --cygnus influence; we want to reserve
## 'install-info' for the user.
##
## TEXINFOS primary are always installed in infodir, hence install-data
## is hard coded.
ifndef am.conf.install-info
ifdef info_TEXINFOS
am__installdirs += "$(DESTDIR)$(infodir)"
install-data-am: install-info-am
endif
endif
.PHONY: \
  install-dvi  install-dvi-am \
  install-html install-html-am \
  install-info install-info-am \
  install-pdf  install-pdf-am \
  install-ps   install-ps-am

ifdef SUBDIRS
RECURSIVE_TARGETS += \
  install-dvi-recursive \
  install-html-recursive \
  install-info-recursive \
  install-pdf-recursive \
  install-ps-recursive
install-dvi: install-dvi-recursive
install-html: install-html-recursive
install-info: install-info-recursive
install-pdf: install-pdf-recursive
install-ps: install-ps-recursive
else
install-dvi: install-dvi-am
install-html: install-html-am
install-info: install-info-am
install-pdf: install-pdf-am
install-ps: install-ps-am
endif

ifdef info_TEXINFOS

# In GNU make, '$^' used in a recipe contains every dependency for the
# target, even those not declared when the recipe is read; for example,
# on:
#    all: foo1; @echo $^
#    all: foo2
# "make all" would output "foo1 foo2".  In our usage, a dependency like
# "install-pdf-am: install-pdf-local" (that is automatically output by
# Automake-NG if the 'install-pdf-local' target is declared) would make
# '$^' unusable as a pure list of PDF target files in the recipe of
# 'install-pdf-am'.  So we need the following indirections.

install-dvi-am:  .am/install-dvi
install-ps-am:   .am/install-ps
install-pdf-am:  .am/install-pdf
install-info-am: .am/install-info
install-html-am: .am/install-html

.am/install-html: $(HTMLS)
	@$(NORMAL_INSTALL)
	$(call am.texi.create-installdir,$(htmldir))
	@list=''; \
	$(if $(and $(HTMLS),$(htmldir)),$(foreach i,$(HTMLS), \
	  p=$(call am.vpath.rewrite,$i); \
	  f=$(notdir $i); \
	  if test -d "$$p"; then \
	    echo " $(MKDIR_P) '$(DESTDIR)$(htmldir)/$$f'"; \
	    $(MKDIR_P) "$(DESTDIR)$(htmldir)/$$f" || exit 1; \
	    echo " $(INSTALL_DATA) '$$p'/* '$(DESTDIR)$(htmldir)/$$f'"; \
	    $(INSTALL_DATA) "$$p"/* "$(DESTDIR)$(htmldir)/$$f" || exit $$?; \
	  else \
	    list="$$list $$p"; \
	  fi;)) \
	test -z "$$list" || { echo "$$list" | $(am__base_list) | \
	while read files; do \
	  echo " $(INSTALL_DATA) $$files '$(DESTDIR)$(htmldir)'"; \
	  $(INSTALL_DATA) $$files "$(DESTDIR)$(htmldir)" || exit $$?; \
	done; }

.am/install-info: $(INFO_DEPS)
	@$(NORMAL_INSTALL)
	$(call am.texi.create-installdir,$(infodir))
	@list='$(and $(infodir),$^)'; test -n "$$list" || exit 0; \
	for p in $$list; do echo "$$p"; done | $(am__base_list) | \
	while read files; do \
	  echo " $(INSTALL_DATA) $$files '$(DESTDIR)$(infodir)'"; \
	  $(INSTALL_DATA) $$files "$(DESTDIR)$(infodir)" || exit $$?; \
	done
	@$(POST_INSTALL)
	@$(am.texi.can-run-installinfo) || exit 0; \
	rellist='$(notdir $(and $(infodir),$^))'; \
	test -n "$$rellist" || exit 0; \
	for relfile in $$rellist; do \
	  echo " install-info --info-dir='$(DESTDIR)$(infodir)' '$(DESTDIR)$(infodir)/$$relfile'";\
## Run ":" after install-info in case install-info fails.  We really
## don't care about failures here, because they can be spurious.  For
## instance if you don't have a dir file, install-info will fail.  I
## think instead it should create a new dir file for you.  This bug
## causes the "make distcheck" target to fail reliably.
	  install-info --info-dir="$(DESTDIR)$(infodir)" "$(DESTDIR)$(infodir)/$$relfile" || :;\
	done; \

.am/install-dvi: $(DVIS)
	@$(NORMAL_INSTALL)
	$(call am.texi.create-installdir,$(dvidir))
	@list='$(and $(dvidir),$^)'; test -n "$$list" || exit 0; \
	for p in $$list; do echo "$$p"; done | $(am__base_list) | \
	while read files; do \
	  echo " $(INSTALL_DATA) $$files '$(DESTDIR)$(dvidir)'"; \
	  $(INSTALL_DATA) $$files "$(DESTDIR)$(dvidir)" || exit $$?; \
	done

.am/install-pdf: $(PDFS)
	@$(NORMAL_INSTALL)
	$(call am.texi.create-installdir,$(pdfdir))
	@list='$(and $(pdfdir),$^)'; test -n "$$list" || exit 0; \
	for p in $$list; do echo "$$p"; done | $(am__base_list) | \
	while read files; do \
	  echo " $(INSTALL_DATA) $$files '$(DESTDIR)$(pdfdir)'"; \
	  $(INSTALL_DATA) $$files "$(DESTDIR)$(pdfdir)" || exit $$?; \
	done

.am/install-ps: $(PSS)
	@$(NORMAL_INSTALL)
	$(call am.texi.create-installdir,$(psdir))
	@list='$(and $(psdir),$^)'; test -n "$$list" || exit 0; \
	for p in $$list; do echo "$$p"; done | $(am__base_list) | \
	while read files; do \
	  echo " $(INSTALL_DATA) $$files '$(DESTDIR)$(psdir)'"; \
	  $(INSTALL_DATA) $$files "$(DESTDIR)$(psdir)" || exit $$?; \
	done

else # !info_TEXINFOS
install-dvi-am:
install-html-am:
install-info-am:
install-pdf-am:
install-ps-am:
endif # !info_TEXINFOS


## --------------------------- ##
## Uninstalling and cleaning.  ##
## --------------------------- ##

ifdef info_TEXINFOS

.PHONY uninstall-am: \
  uninstall-dvi-am \
  uninstall-html-am \
  uninstall-info-am \
  uninstall-ps-am \
  uninstall-pdf-am

uninstall-dvi-am:
	@$(NORMAL_UNINSTALL)
	$(call am.uninst.cmd,$(dvidir),$(notdir $(DVIS)))

uninstall-pdf-am:
	@$(NORMAL_UNINSTALL)
	$(call am.uninst.cmd,$(pdfdir),$(notdir $(PDFS)))

uninstall-ps-am:
	@$(NORMAL_UNINSTALL)
	$(call am.uninst.cmd,$(psdir),$(notdir $(PSS)))

uninstall-html-am:
	@$(NORMAL_UNINSTALL)
## The HTML 'files' can be directories actually, hence the '-r'.
	$(call am.uninst.cmd,$(htmldir),$(notdir $(HTMLS)),-r)

uninstall-info-am:
	@$(PRE_UNINSTALL)
## Run two loops here so that we can handle PRE_UNINSTALL and
## NORMAL_UNINSTALL correctly.
	@if test -d '$(DESTDIR)$(infodir)' && $(am.texi.can-run-installinfo); then \
	  list='$(notdir $(INFO_DEPS))'; for relfile in $$list; do \
## install-info needs the actual info file.  We use the installed one,
## rather than relying on one still being in srcdir or builddir.
## However, "make uninstall && make uninstall" should not fail,
## so we ignore failure if the file did not exist.
	    echo " install-info --info-dir='$(DESTDIR)$(infodir)' --remove '$(DESTDIR)$(infodir)/$$relfile'"; \
	    if install-info --info-dir="$(DESTDIR)$(infodir)" --remove "$(DESTDIR)$(infodir)/$$relfile"; \
	    then :; else test ! -f "$(DESTDIR)$(infodir)/$$relfile" || exit 1; fi; \
	  done; \
	else :; fi
	@$(NORMAL_UNINSTALL)
	$(call am.uninst.cmd,$(infodir),$(notdir $(INFO_DEPS)))


.PHONY: dist-info
dist-info: $(INFO_DEPS)
	@$(foreach f,$^,cp -p $f $(distdir)/$(patsubst $(srcdir)/%,%,$f);)

am.clean.maint.f += $(INFO_DEPS)

endif # !info_TEXINFOS