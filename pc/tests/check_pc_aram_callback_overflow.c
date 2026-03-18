#include <stdint.h>

#include "dolphin/ar.h"

static void overflow_callback(u32 req) {
    (void)req;
}

int main(void) {
    ARQPostRequest((void*)(uintptr_t)0x100000000ULL, 0, ARQ_TYPE_MRAM_TO_ARAM, ARQ_PRIORITY_LOW, 0, 0, 0,
                   overflow_callback);
    return 0;
}
