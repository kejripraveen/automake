#! /bin/sh
# Copyright (C) 2010-2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Test basic remake rules for Makefiles, for a *VPATH build*.
# This testcase checks dependency of generated Makefile from Makefile.am,
# configure.ac, acinclude.m4, aclocal.m4, and extra m4 files considered
# by aclocal.
# Keep this in sync with sister test 'remake8a.test', which performs the
# same checks for a in-tree build.

. ./defs || Exit 1

mv -f configure.ac configure.stub

cat > Makefile.am <<'END'
all-local: foo
foo:
	echo '!Foo!' >$@
check-local:
	cat foo
	grep '!Foo!' foo
CLEANFILES = foo
END

cat configure.stub - > configure.ac <<'END'
AC_OUTPUT
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

mkdir build
cd build
srcdir='..' # To make syncing with remake8a.test easier.

$srcdir/configure

$MAKE
cat foo
grep '!Foo!' foo
$MAKE distcheck

rm -f foo

# Modify just Makefile.am.

$sleep

cat > $srcdir/Makefile.am <<'END'
all-local: bar
bar:
	echo '!Baz!' >$@
check-local:
	cat bar
	grep '!Baz!' bar
	test ! -r $(srcdir)/foo
	test ! -r foo
CLEANFILES = bar
END

$MAKE
cat bar
grep '!Baz!' bar
test ! -r foo
$MAKE distcheck

rm -f bar

# Modify Makefile.am and configure.ac.

$sleep

cat > $srcdir/Makefile.am <<'END'
check-local:
	cat quux
	grep '!Zardoz!' quux
	test ! -r $(srcdir)/bar
	test ! -r bar
END

cat $srcdir/configure.stub - > $srcdir/configure.ac <<'END'
AC_CONFIG_FILES([quux])
AC_SUBST([QUUX], [Zardoz])
AC_OUTPUT
END

cat > $srcdir/quux.in <<'END'
!@QUUX@!
END

$MAKE
cat quux
grep '!Zardoz!' quux
test ! -r bar
$MAKE distcheck

rm -f quux

# Modify Makefile.am to add a directory of extra m4 files
# considered by aclocal.

$sleep

mkdir $srcdir/m4

cat > $srcdir/Makefile.am <<'END'
ACLOCAL_AMFLAGS = -I m4
check-local:
	cat quux
	grep '%Foo%' quux
	test x'$(QUUX)' = x'%Foo%'
END

$MAKE # This should place aclocal flags in Makefile.
grep '.*-I m4' Makefile # Sanity check.

# Modify configure.ac and aclocal.m4.

$sleep

cat $srcdir/configure.stub - > $srcdir/configure.ac <<'END'
AC_CONFIG_FILES([quux])
MY_CUSTOM_MACRO
AC_OUTPUT
END

cat >> $srcdir/aclocal.m4 <<'END'
AC_DEFUN([MY_CUSTOM_MACRO], [AC_SUBST([QUUX], [%Foo%])])
END

$MAKE
cat quux
grep '%Foo%' quux
$MAKE distcheck

# Modify Makefile.am, remove aclocal.m4, and add a new m4 file to
# the directory of extra m4 files considered by aclocal.  This new
# file should now provide a macro required by configure.ac and that
# was previously provided by aclocal.m4.

$sleep

sed 's/%Foo%/%Bar%/g' $srcdir/Makefile.am > t
mv -f t $srcdir/Makefile.am
cat $srcdir/Makefile.am
rm -f $srcdir/aclocal.m4
cat > $srcdir/m4/blah.m4 <<'END'
AC_DEFUN([MY_CUSTOM_MACRO], [AC_SUBST([QUUX], [%Bar%])])
END

$MAKE
cat quux
grep '%Bar%' quux
$MAKE distcheck

# Modify Makefile.am, remove all the extra m4 files to considered
# by aclocal, and add an acinclude.m4 file.  This last file should
# now provide a macro required by configure.ac, and that was
# previously provided by the extra m4 files considered by aclocal.

$sleep

rm -f $srcdir/m4/*.m4
sed 's/%Bar%/%Quux%/g' $srcdir/Makefile.am > t
mv -f t $srcdir/Makefile.am
cat $srcdir/Makefile.am
cat > $srcdir/acinclude.m4 <<'END'
AC_DEFUN([MY_CUSTOM_MACRO], [AC_SUBST([QUUX], [%Quux%])])
END

$MAKE
cat quux
grep '%Quux%' quux
$MAKE distcheck

: