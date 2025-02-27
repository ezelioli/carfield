# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>
# Yvan Tortorella <yvan.tortorella@unibo.it>

.PHONY: all clean

# Make fragment for integer cluster bare-metal tests compiled with pulp-runtime.

# List all the directories in the 'tests' folder
PULPD_SW_DIR := $(PULPD_ROOT)/regression-tests/parallel_bare_tests
PULPD_TEST_DIRS := $(wildcard $(PULPD_ROOT)/regression-tests/parallel_bare_tests/*)
PULPD_TEST_DIRS := $(filter-out $(wildcard $(PULPD_ROOT)/regression-tests/parallel_bare_tests/*.cfg),$(PULPD_TEST_DIRS))

# Generate the list of build targets based on the directories
PULPD_BUILD_TARGETS := $(addsuffix /build,$(PULPD_TEST_DIRS))

# We have a target per test. The target (1) compiles the binary and (2) generates the needed stimuli
# file format, if any is required.
$(PULPD_SW_DIR)/%/build: $(PULPD_ROOT) | venv
	# Compile
	$(MAKE) -C $(PULPD_SW_DIR)/$* all
	@echo $(PULPD_SW_DIR)

# Convert compiled binaries to header files
PULPD_HEADER_TARGETS := $(patsubst $(PULPD_SW_DIR)/%, $(CAR_SW_DIR)/tests/bare-metal/pulpd/%.h, $(PULPD_TEST_DIRS))

$(CAR_SW_DIR)/tests/bare-metal/pulpd/%.h: $(PULPD_SW_DIR)/%/build/test/test | venv
	$(VENV)/python $(CAR_ROOT)/scripts/elf2header.py --binary $< --vectors $@

# Global targets
pulpd-sw-all: $(PULPD_BUILD_TARGETS) $(PULPD_HEADER_TARGETS)

pulpd-sw-clean:
	# Clean all the directories in 'tests'
	$(foreach dir, $(PULPD_TEST_DIRS), $(MAKE) -C $(dir) clean;)
	$(RM) $(CAR_SW_DIR)/tests/bare-metal/pulpd/*.h
