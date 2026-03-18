#ifndef PC_RUNTIME_PTR_H
#define PC_RUNTIME_PTR_H

#if defined(TARGET_PC)

#include <stdint.h>
#include <stdlib.h>

static inline unsigned int pc_runtime_u32_ptr_checked(uintptr_t value) {
#if defined(PC_EXPERIMENTAL_64BIT)
    if ((value & ~(uintptr_t)0xffffffffu) != 0) {
        abort();
    }
#endif

    return (unsigned int)value;
}

#define PC_RUNTIME_U32_PTR(value) pc_runtime_u32_ptr_checked((uintptr_t)(value))

#else

#define PC_RUNTIME_U32_PTR(value) ((unsigned int)(value))

#endif

#endif
