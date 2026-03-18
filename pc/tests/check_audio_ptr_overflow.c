#include <stdint.h>

#include "jaudio_NES/audiocommon.h"

int main(void) {
    return NA_AUDIO_PTR_PARAM((void*)(uintptr_t)0x100000000ULL);
}
