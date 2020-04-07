#   Makefile            # - Makefile for auto-generated tests
#    
# ====================
#   Created: 2020-04-07
#   Author: tabulon [TAU]
#   Project: Getopt::Long::More
# -----
# COPYRIGHT & LICENSE:
#   Copyright 2019 - 2020 /tabulo.*/i
#   License: Artistic License 2.0
# -----
# NOTES:
#   
#   
# -----
# HISTORY:
#   
#   

GOL = Getopt::Long
GLM = $(GOL)::More

SHELL:=/usr/bin/env bash


all: build-tests

build-tests: gol-authentic gol-conformance

#.PHONY: gol-authentic
gol-authentic:
	../maint/fetch-gol-tests "$@"

#.PHONY: gol-conformance
gol-conformance: gol-authentic
	../maint/adapt-gol-tests "$<" "$@"

clean:
	rm -rf gol-{authentic,conformance}