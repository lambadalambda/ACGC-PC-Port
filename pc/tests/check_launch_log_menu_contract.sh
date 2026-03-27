#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing launch-log contract: $label ($file)" >&2
        exit 1
    fi
}

check_contains "pc/include/pc_settings.h" 'launch_log_file' 'settings struct stores launch log toggle'
check_contains "pc/src/pc_settings.c" 'launch_log_file = 0' 'default settings include launch log toggle'
check_contains "pc/src/pc_settings.c" 'strcmp\(key, "launch_log_file"\)' 'settings loader parses launch log key'
check_contains "pc/src/pc_settings.c" 'fprintf\(f, "launch_log_file = %d\\n", g_pc_settings.launch_log_file\);' 'settings save writes launch log key'

check_contains "pc/src/pc_main.c" 'pc_launch_log_setting_enabled\(void\)' 'pc main can read launch log toggle before redirect'
check_contains "pc/src/pc_main.c" 'pc_platform_get_launch_log_path\(void\)' 'pc main exports launch log path accessor'
check_contains "pc/src/pc_main.c" 'Documents/ACGC' 'launch log targets Documents/ACGC root'
check_contains "pc/src/pc_main.c" 'launch_%04d%02d%02d_%02d%02d%02d_%lu\.log' 'launch log filename is per-launch timestamped'

check_contains "src/actor/ac_animal_logo.c" 'pc_options_sel < 5' 'title options menu supports sixth option'
check_contains "src/actor/ac_animal_logo.c" 'case 5: g_pc_settings.launch_log_file = !g_pc_settings.launch_log_file; break;' 'title options can toggle launch log setting'
check_contains "src/actor/ac_animal_logo.c" "'L', 'a', 'u', 'n', 'c', 'h', ' ', 'L', 'o', 'g'" 'title options draw includes Launch Log label'
check_contains "src/actor/ac_animal_logo.c" 'pc_platform_get_launch_log_path\(\)' 'title options draw reads active launch log path'
check_contains "src/actor/ac_animal_logo.c" 'File: \(next launch\)' 'title options show next-launch log hint'

printf '%s\n' 'check_launch_log_menu_contract: OK'
