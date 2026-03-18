#include "types.h"

_Static_assert(sizeof(s8) == 1, "s8 must be 8-bit");
_Static_assert(sizeof(u8) == 1, "u8 must be 8-bit");
_Static_assert(sizeof(s16) == 2, "s16 must be 16-bit");
_Static_assert(sizeof(u16) == 2, "u16 must be 16-bit");
_Static_assert(sizeof(s32) == 4, "s32 must be 32-bit");
_Static_assert(sizeof(u32) == 4, "u32 must be 32-bit");
_Static_assert(sizeof(s64) == 8, "s64 must be 64-bit");
_Static_assert(sizeof(u64) == 8, "u64 must be 64-bit");
_Static_assert(sizeof(uintptr_t) == sizeof(void*), "uintptr_t must match pointer size");

int main(void) {
    return 0;
}
