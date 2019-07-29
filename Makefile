# AABB.cc Makefile

# Copyright (c) 2016 Lester Hedges <lester.hedges+aabbcc@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

################################ INFO #######################################

# This Makefile can be used to build a CXX project library along with its
# demos and documentation. For detailed information on using the Makefile
# run make without a target, i.e. simply run make at your command prompt.
#
# Makefile style adapted from http://clarkgrubb.com/make-file-style-guide
# Conventions:
#   - Environment and Makefile variables are in upper case, user
#     defined variables are in lower case.
#   - Variables are declared using the immediate assignment operator :=

############################### MACROS ########################################

define colorecho
	@if hash tput 2> /dev/null; then	\
		if [[ -t 1 ]]; then				\
			tput setaf $1;				\
			echo $2;					\
			tput sgr0;					\
		else							\
			echo $2;					\
		fi								\
	else								\
		echo $2;						\
	fi
endef

define boldcolorecho
	@if hash tput 2> /dev/null; then	\
		if [[ -t 1 ]]; then				\
			tput bold;					\
			tput setaf $1;				\
			echo $2;					\
			tput sgr0;					\
		else							\
			echo $2;					\
		fi								\
	else								\
		echo $2;						\
	fi
endef

############################## VARIABLES ######################################

# Set shell to bash.
SHELL := bash

# Suppress display of executed commands.
.SILENT:

# Default goal will print the help message.
.DEFAULT_GOAL := help

# Project name.
project := aabb

# Upper case project name (for use in library header file).
project_upper := `echo $(project) | tr a-z A-Z`

# C++ compiler.
CXX := g++

# Installation path.
PREFIX := /usr/local

# Python version
PYTHON := 2.7

# External libraries.
LIBS :=

# Path for source files.
src_dir := src

# Path for demo code.
demo_dir := demos

# Path for object files.
obj_dir := obj

# Path for the library.
lib_dir := lib

# Path for the python wrapper.
python_dir := python

# Path for the header-only library.
header_only_dir := header-only

# Generate library target name.
library := $(lib_dir)/lib$(project).a

# Header only library file.
header_only_lib := $(header_only_dir)/$(project_upper).hpp

# Install command.
install_cmd := install

# Install flags for executables.
iflags_exec := -m 0755

# Install flags for non-executable files.
iflags := -m 0644

# Git commit information.
commit := $(shell git describe --abbrev=4 --dirty --always --tags 2> /dev/null)

# Git branch information.
branch := $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null)

# Python binary.
python_binary := $(shell which python$(PYTHON))

# SWIG binary.
swig_binary := $(shell which swig)

# C++ compiler flags for development build.
cxxflags_devel := -O0 -std=c++11 -g -Wall -Isrc -DCOMMIT=\"$(commit)\" -DBRANCH=\"$(branch)\" $(OPTFLAGS)

# C++ compiler flags for release build.
cxxflags_release := -O3 -std=c++11 -DNDEBUG -Isrc -DCOMMIT=\"$(commit)\" -DBRANCH=\"$(branch)\" $(OPTFLAGS)

# Default to release build.
CXXFLAGS := $(cxxflags_release)

# The C++ header, source, object, and dependency files.
headers := $(wildcard $(src_dir)/*.h)
sources := $(wildcard $(src_dir)/*.cc)
temp := $(patsubst %.cc,%.o,$(sources))
objects := $(subst $(src_dir),$(obj_dir),$(temp))
-include $(subst .o,.d,$(objects))

# Source files and executable names for demos.
demo_sources := $(wildcard $(demo_dir)/*.cc)
demos := $(patsubst %.cc,%,$(demo_sources))

# Doxygen files.
dox_files := $(wildcard dox/*.dox)

############################### TARGETS #######################################

# Print help message.
.PHONY: help
help:
	$(call boldcolorecho, 4, "About")
	@echo " This Makefile can be used to build the $(project) library along with its"
	@echo " demos and documentation."
	@echo
	$(call boldcolorecho, 4, "Targets")
	@echo " help        -->  print this help message"
	@echo " build       -->  build library and demos (default=release)"
	@echo " devel       -->  build using development compiler flags (debug)"
	@echo " release     -->  build using release compiler flags (optmized)"
	@echo " python      -->  build the python wrapper"
	@echo " header-only -->  create a header-only version of the library"
	@echo " doc         -->  generate source code documentation with doxygen"
	@echo " clean       -->  remove object and dependency files"
	@echo " clobber     -->  remove all files generated by make"
	@echo " install     -->  install library, demos, and documentation"
	@echo " uninstall   -->  uninstall library, demos, and documentation"

# Set development compilation flags and build.
devel: CXXFLAGS := $(cxxflags_devel)
devel: build

# Set release compilation flags and build.
release: CXXFLAGS := $(cxxflags_release)
release: build

# Print compiler flags.
devel release:
	$(call colorecho, 5, "--> CXXFLAGS: $(CXXFLAGS)")

# Save compiler flags to file if they differ from previous build.
# This target ensures that all object files are recompiled if the flags change.
.PHONY: force
.compiler_flags: force
	@echo '$(CXXFLAGS)' | cmp -s - $@ || echo '$(CXXFLAGS)' > $@

# Check that python and swig binaries are present.
# This target ensures that all python demos are recompiled if the .check_python file changes.
.PHONY: force
.check_python: force
	@echo "Python found." | cmp -s - $@ || \
	if [ "$(python_binary)" = "" ] || [ "$(swig_binary)" = "" ] ; then \
        echo "Python not found."; \
        exit 1; \
	else echo "Python found."; \
	fi > $@

# Compile object files.
# Autodepenencies are handled using a recipe taken from
# http://scottmcpeak.com/autodepend/autodepend.html
$(obj_dir)/%.o: $(src_dir)/%.cc .compiler_flags
	$(call colorecho, 2, "--> Building CXX object $*.o")
	$(CXX) $(CXXFLAGS) -c -o $(obj_dir)/$*.o $(src_dir)/$*.cc
	$(CXX) -MM $(CXXFLAGS) $(src_dir)/$*.cc > $*.d
	@mv -f $*.d $*.d.tmp
	@sed -e 's|.*:|$(obj_dir)/$*.o:|' < $*.d.tmp > $(obj_dir)/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
		sed -e 's/^ *//' -e 's/$$/:/' >> $(obj_dir)/$*.d
	@rm -f $*.d.tmp

# Build the library and demos.
.PHONY: build
build: $(obj_dir) $(library) $(demos) python

# Create output directory for object and dependency files.
$(obj_dir):
	mkdir $(obj_dir)

# Build the static library.
$(library): $(objects)
	$(call colorecho, 1, "--> Linking CXX static library $(library)")
	mkdir -p $(lib_dir)
	ar rcs $@ $(objects)
	ranlib $@

# Compile demonstration code.
$(demos): %: %.cc $(library)
	$(call colorecho, 1, "--> Linking CXX executable $@")
	$(CXX) $(CXXFLAGS) $@.cc $(library) $(LIBS) $(LDFLAGS) -o $@

# Build the python wrapper.
.PHONY: python
python: .check_python $(python_dir)/aabb.i $(python_dir)/setup.py
	$(call colorecho, 2, "--> Building Python wrapper")
	cd $(python_dir)                                    ;\
	$(swig_binary) -builtin -c++ -python aabb.i         ;\
	$(python_binary) setup.py -q build_ext --inplace

# Create the header only library.
.PHONY: header-only
header-only: $(headers) $(sources)
	mkdir -p $(header_only_dir)
	head -n 499 src/AABB.h > $(header_only_lib)
	echo >> $(header_only_lib)
	tail +29 src/AABB.cc >> $(header_only_lib)
	echo >> $(header_only_lib)
	echo "#endif /* _AABB_H */" >> $(header_only_lib)

# Build documentation using Doxygen.
doc: $(headers) $(sources) $(dox_files)
	$(call colorecho, 4, "--> Generating CXX source documentation with Doxygen")
	doxygen dox/Doxyfile

# Install the library and demos.
.PHONY: install
install: build doc
	$(call colorecho, 3, "--> Installing CXX static library $(library) to $(PREFIX)/lib")
	$(call colorecho, 3, "--> Installing Python wrapper to $(PREFIX)/lib/python$(PYTHON)")
	$(call colorecho, 3, "--> Installing CXX demos $(demos) to $(PREFIX)/share/$(project)-demos")
	$(call colorecho, 3, "--> Installing CXX Doxygen documentation to $(PREFIX)/share/doc/$(project)")
	$(install_cmd) -d $(iflags_exec) $(PREFIX)/lib
	$(install_cmd) -d $(iflags_exec) $(PREFIX)/lib/python$(PYTHON)
	$(install_cmd) -d $(iflags_exec) $(PREFIX)/include/$(project)
	$(install_cmd) -d $(iflags_exec) $(PREFIX)/share/$(project)-demos
	$(install_cmd) -d $(iflags_exec) $(PREFIX)/share/doc/$(project)
	$(install_cmd) $(iflags) $(library) $(PREFIX)/lib
	$(install_cmd) $(iflags) $(python_dir)/aabb.py $(PREFIX)/lib/python$(PYTHON)
	$(install_cmd) $(iflags_exec) $(python_dir)/_aabb.so $(PREFIX)/lib/python$(PYTHON)
	$(install_cmd) $(iflags) $(headers) $(PREFIX)/include/$(project)
	$(install_cmd) $(iflags) $(demo_sources) $(PREFIX)/share/$(project)-demos
	$(install_cmd) $(iflags_exec) $(demos) $(PREFIX)/share/$(project)-demos
	cp -r doc/html $(PREFIX)/share/doc/$(project)

# Uninstall the library and demos.
.PHONY: uninstall
uninstall:
	$(call colorecho, 3, "--> Uninstalling CXX static library $(library) from $(PREFIX)/lib")
	$(call colorecho, 3, "--> Uninstalling Python wrapper from $(PREFIX)/lib/python$(PYTHON)")
	$(call colorecho, 3, "--> Uninstalling CXX demos $(demos) from $(PREFIX)/share/$(project)-demos")
	$(call colorecho, 3, "--> Uninstalling CXX Doxygen documentation from $(PREFIX)/share/doc/$(project)")
	rm -f $(PREFIX)/$(library)
	rm -f $(PREFIX)/lib/python$(PYTHON)/aabb.py
	rm -f $(PREFIX)/lib/python$(PYTHON)/_aabb.so
	rm -rf $(PREFIX)/include/$(project)
	rm -rf $(PREFIX)/share/$(project)-demos
	rm -rf $(PREFIX)/share/doc/$(project)

# Clean up object and dependecy files.
.PHONY: clean
clean:
	$(call colorecho, 6, "--> Cleaning CXX object and dependency files")
	rm -rf $(obj_dir)

# Clean up everything produced by make.
.PHONY: clobber
clobber:
	$(call colorecho, 6, "--> Cleaning all output files")
	rm -rf $(obj_dir)
	rm -rf $(lib_dir)
	rm -rf $(python_dir)/build
	rm -rf $(python_dir)/_aabb.*
	rm -rf $(python_dir)/aabb_wrap.cxx
	rm -rf $(python_dir)/aabb.py*
	rm -rf $(python_dir)/__pycache__
	rm -rf $(header_only_dir)
	rm -rf doc
	rm -f $(demos)
	rm -rf $(demo_dir)/*dSYM
	rm -f .compiler_flags
	rm -f .check_python

.PHONY: sandwich
sandwich:
	if [ "$$(id -u)" != "0" ]; then                        \
		echo " What? Make it yourself."                   ;\
	else                                                   \
		echo "                      ____"                 ;\
		echo "          .----------'    '-."              ;\
		echo "         /  .      '     .   \\"            ;\
		echo "        /        '    .      /|"            ;\
		echo "       /      .             \ /"            ;\
		echo "      /  ' .       .     .  || |"           ;\
		echo "     /.___________    '    / //"            ;\
		echo "     |._          '------'| /|"             ;\
		echo "     '.............______.-' /"             ;\
		echo "     |-.                  | /"              ;\
		echo "     \`\"\"\"\"\"\"\"\"\"\"\"\"\"-.....-'"  ;\
	fi;                                                    \
