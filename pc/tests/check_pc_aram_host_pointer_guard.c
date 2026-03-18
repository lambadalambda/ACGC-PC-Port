#include <stdint.h>

#include "dolphin/ar.h"

u8* pc_aram_get_base(void);

int main(void) {
    u8 scratch[32] = { 0 };
    uintptr_t base;

    ARInit(0, 0);
    base = (uintptr_t)pc_aram_get_base();

    if (base <= 0xffffffffu) {
        return 0;
    }

    ARStartDMA(ARAM_DIR_MRAM_TO_ARAM, (u32)(uintptr_t)scratch, (u32)base, 0);
    return 1;
}
