ifeq (3.81,$(MAKE_VERSION))
  $(error You seem to be using the OSX antiquated Make version. Hint: brew \
    install make, then invoke gmake instead of make)
endif

all: build-tests-verify

CHARON_HOME = ../charon
CHARON_EXEC = $(CHARON_HOME)/charon
DEST_DIR = tests

# We use those variables, whose definition depends on the rule we apply
CHARON_TESTS_DIR =
CHARON_OPTIONS =
CHARON_TESTS_SRC =

AENEAS_DRIVER = driver.exe

# The user can specify additional translation options for Aeneas:
OPTIONS ?=

# Default translation options:
# - insert calls to the normalizer in the translated code to test the
#   generated unit functions
TRANS_OPTIONS := -test-trans-units $(OPTIONS)
SUBDIR :=

# Build the project, test it and verify the generated files
.PHONY: build-test-verify
build-tests-verify: build tests verify

# Build the project
.PHONY: build
build: build-driver build-lib doc

.PHONY: build-driver
build-driver:
	cd compiler && dune build $(AENEAS_DRIVER)

.PHONY: build-lib
build-lib:
	cd compiler && dune build aeneas.cmxs

.PHONY: doc
doc:
	cd compiler && dune build @doc

.PHONY: clean
clean:
	cd compiler && dune clean

# Test the project by translating test files to F*
.PHONY: tests
tests: build trans-no_nested_borrows trans-paper \
	trans-hashmap trans-hashmap_main \
	trans-external trans-constants \
	trans-polonius-betree_polonius trans-polonius-betree_main

# Verify the F* files generated by the translation
.PHONY: verify
verify: build tests
	cd tests && $(MAKE) all

# Reformat the project
.PHONY: format
format:
	cd compiler && dune promote

# Add specific options to some tests
trans-no_nested_borrows trans-paper: \
	TRANS_OPTIONS += -test-units -no-split-files -no-state -no-decreases-clauses
trans-no_nested_borrows trans-paper: SUBDIR:=misc

trans-hashmap: TRANS_OPTIONS += -template-clauses -no-state
trans-hashmap: SUBDIR:=hashmap

trans-hashmap_main: TRANS_OPTIONS += -template-clauses
trans-hashmap_main: SUBDIR:=hashmap_on_disk

trans-polonius-betree_polonius: TRANS_OPTIONS += -test-units -no-split-files -no-state -no-decreases-clauses
trans-polonius-betree_polonius: SUBDIR:=misc

trans-constants: TRANS_OPTIONS += -test-units -no-split-files -no-state -no-decreases-clauses
trans-constants: SUBDIR:=misc

trans-external: TRANS_OPTIONS +=
trans-external: SUBDIR:=misc

trans-polonius-betree_main: TRANS_OPTIONS += -template-clauses
trans-polonius-betree_main: SUBDIR:=betree

# Generic rules to extract the LLBC from a rust file
# We use the rules in Charon's Makefile to generate the .llbc files: the options
# vary with the test files.
.PHONY: gen-llbc-polonius-%
gen-llbc-polonius-%: build
	cd $(CHARON_HOME)/tests-polonius && $(MAKE) test-$*

.PHONY: gen-llbc-%
gen-llbc-%: build
	cd $(CHARON_HOME)/tests && $(MAKE) test-$*

# Generic rule to test the translation of an LLBC file.
# Note that the files requiring the Polonius borrow-checker are generated
# in the tests-polonius subdirectory.
.PHONY: trans-%
trans-%: CHARON_TESTS_DIR = $(CHARON_HOME)/tests/llbc
trans-polonius-%: CHARON_TESTS_DIR = $(CHARON_HOME)/tests-polonius/llbc

trans-polonius-%: gen-llbc-polonius-%
	cd compiler && dune exec -- ./$(AENEAS_DRIVER) ../$(CHARON_TESTS_DIR)/$*.llbc -dest ../$(DEST_DIR)/$(SUBDIR) $(TRANS_OPTIONS)

trans-%: gen-llbc-%
	cd compiler && dune exec -- ./$(AENEAS_DRIVER) ../$(CHARON_TESTS_DIR)/$*.llbc -dest ../$(DEST_DIR)/$(SUBDIR) $(TRANS_OPTIONS)
