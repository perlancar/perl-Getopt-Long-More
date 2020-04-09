#   Makefile            # - Makefile for auto-generated tests
#    
# ====================
#   Created: 2020-04-07
#   Author: tabulon [TAU]
#   Project: Getopt::Long::More
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

build-tests: gol-authentique gol-conformance

.PHONY: gol-authentique
gol-authentique:
	../maint/fetch-gol-tests "$@"

.PHONY: gol-conformance
gol-conformance: gol-authentique
	../maint/adapt-gol-tests "$<" "$@"

clean:
	rm -rf gol-{authentic,conformance}