#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JKR archive LP64 file-entry contract: $label" >&2
        exit 1
    fi
}

for file in \
    "src/static/JSystem/JKernel/JKRAramArchive.cpp" \
    "src/static/JSystem/JKernel/JKRDvdArchive.cpp" \
    "src/static/JSystem/JKernel/JKRCompArchive.cpp" \
    "src/static/JSystem/JKernel/JKRMemArchive.cpp"
do
    check_contains "$file" 'struct SDIFileEntryDisk' "$file disk entry struct"
    check_contains "$file" 'static_assert\(sizeof\(SDIFileEntryDisk\) == 0x14' "$file disk entry size assert"
    check_contains "$file" 'if \(sizeof\(void\*\) > 4\)' "$file LP64 branch"
    check_contains "$file" 'sizeof\(SDIFileEntry\) \* mArcInfoBlock->num_file_entries' "$file host entry allocation"
done

check_contains "src/static/JSystem/JKernel/JKRAramArchive.cpp" 'mFileEntries != raw_file_entries' 'aram archive host entry cleanup'
check_contains "src/static/JSystem/JKernel/JKRDvdArchive.cpp" 'mFileEntries != raw_file_entries' 'dvd archive host entry cleanup'
check_contains "src/static/JSystem/JKernel/JKRCompArchive.cpp" 'mFileEntries != raw_file_entries' 'comp archive host entry cleanup'
check_contains "src/static/JSystem/JKernel/JKRMemArchive.cpp" 'mFileEntries != raw_file_entries' 'mem archive host entry cleanup'
