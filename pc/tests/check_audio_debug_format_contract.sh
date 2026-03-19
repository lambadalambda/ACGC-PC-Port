#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio debug format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio debug format: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/jammain_2.c" 'OSReport\("SEQP %p  Access Offset %d\\n", \(void\*\)track, track->programCounter\);' 'jaudio sequence debug report uses %p'
check_contains "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL USE %p\\n", \(void\*\)&AG.channel_node.useList\);' 'jaudio use-list debug report uses %p'
check_contains "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL FREE %p\\n", \(void\*\)&AG.channel_node.freeList\);' 'jaudio free-list debug report uses %p'
check_contains "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL RELEASE %p\\n", \(void\*\)&AG.channel_node.releaseList\);' 'jaudio release-list debug report uses %p'
check_contains "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL RELWAIT %p\\n", \(void\*\)&AG.channel_node.relwaitList\);' 'jaudio relwait-list debug report uses %p'
check_contains "src/static/jaudio_NES/internal/track.c" 'OSReport\("List %p\\n", \(void\*\)list\);' 'jaudio list debug report uses %p'
check_contains "src/static/jaudio_NES/internal/track.c" 'OSReport\("Root %p\\n", \(void\*\)root\);' 'jaudio root debug report uses %p'

check_absent "src/static/jaudio_NES/internal/jammain_2.c" 'OSReport\("SEQP %x  Access Offset %d\\n", track, track->programCounter\);' 'legacy sequence debug report'
check_absent "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL USE %x\\n", &AG.channel_node.useList\);' 'legacy use-list debug report'
check_absent "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL FREE %x\\n", &AG.channel_node.freeList\);' 'legacy free-list debug report'
check_absent "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL RELEASE %x\\n", &AG.channel_node.releaseList\);' 'legacy release-list debug report'
check_absent "src/static/jaudio_NES/internal/track.c" 'OSReport\("GLOBAL RELWAIT %x\\n", &AG.channel_node.relwaitList\);' 'legacy relwait-list debug report'
check_absent "src/static/jaudio_NES/internal/track.c" 'OSReport\("List %x\\n", list\);' 'legacy list debug report'
check_absent "src/static/jaudio_NES/internal/track.c" 'OSReport\("Root %x\\n", root\);' 'legacy root debug report'
