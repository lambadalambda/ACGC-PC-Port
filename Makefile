SHELL := /bin/sh

SOURCE_DIR := pc
BUILD_DIR ?= pc/build-macos

ifeq ($(MSYSTEM),MINGW32)
CMAKE_GENERATOR_ARG ?= -G "MinGW Makefiles"
endif
CMAKE_GENERATOR_ARG ?=

CMAKE_OPTIONS ?= -DPC_EXPERIMENTAL_64BIT=ON
JOBS ?= $(shell sh -c 'command -v nproc >/dev/null 2>&1 && nproc || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4')

.PHONY: all configure build dirs clean distclean help

all: build

configure:
	cmake -S "$(SOURCE_DIR)" -B "$(BUILD_DIR)" $(CMAKE_GENERATOR_ARG) $(CMAKE_OPTIONS)

build: configure
	cmake --build "$(BUILD_DIR)" --parallel "$(JOBS)"
	$(MAKE) dirs

dirs:
	mkdir -p "$(BUILD_DIR)/bin/rom"
	mkdir -p "$(BUILD_DIR)/bin/texture_pack"
	mkdir -p "$(BUILD_DIR)/bin/save"

clean:
	cmake --build "$(BUILD_DIR)" --target clean

distclean:
	rm -rf "$(BUILD_DIR)"

help:
	@printf '%s\n' 'Targets:'
	@printf '  %-14s %s\n' 'make' 'Configure + build application (default)'
	@printf '  %-14s %s\n' 'make configure' 'Run CMake configure step only'
	@printf '  %-14s %s\n' 'make build' 'Build configured target'
	@printf '  %-14s %s\n' 'make clean' 'Clean build outputs in build directory'
	@printf '  %-14s %s\n' 'make distclean' 'Remove build directory'
	@printf '%s\n' ''
	@printf '%s\n' 'Variables:'
	@printf '  %-26s %s\n' 'BUILD_DIR=pc/build-macos' 'Build directory'
	@printf '  %-26s %s\n' 'CMAKE_OPTIONS=...' 'Extra CMake options (LP64 bringup is enabled by default)'
	@printf '  %-26s %s\n' 'CMAKE_GENERATOR_ARG=...' 'Optional explicit CMake generator argument'
