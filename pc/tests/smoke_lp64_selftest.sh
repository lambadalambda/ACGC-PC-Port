#!/bin/sh

set -eu

LP64_BUILD_DIR=${1:-/tmp/acgc-p2-config-64}
LP64_ASAN_BUILD_DIR=${2:-/tmp/acgc-p2-config-64-asan}

run_selftest() {
    build_dir=$1
    label=$2
    bin="$build_dir/bin/AnimalCrossing"

    if [ ! -x "$bin" ]; then
        printf '%s\n' "missing $label binary: $bin" >&2
        return 1
    fi

    output=$("$bin" --selftest)

    if ! printf '%s\n' "$output" | rg -q '^\[PC\] selftest: ok \(ptr=8 lp64=1\)$'; then
        printf '%s\n' "unexpected $label selftest output: $output" >&2
        return 1
    fi

    printf '%s\n' "[selftest] $label: $output"
}

run_selftest "$LP64_BUILD_DIR" "lp64"
run_selftest "$LP64_ASAN_BUILD_DIR" "lp64-asan"
