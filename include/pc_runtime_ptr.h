#ifndef PC_RUNTIME_PTR_H
#define PC_RUNTIME_PTR_H

#if defined(TARGET_PC)

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

static inline unsigned int pc_runtime_u32_ptr_checked_at(uintptr_t value, const char* expr, const char* file, int line) {
#if defined(PC_EXPERIMENTAL_64BIT)
    if ((value & ~(uintptr_t)0xffffffffu) != 0) {
        /* Fail fast with source context so LP64 truncation regressions are
         * attributable to a concrete callsite in smoke logs. */
        fprintf(stderr, "[PC][LP64] PC_RUNTIME_U32_PTR overflow: %s=0x%llx at %s:%d\n", expr,
                (unsigned long long)value, file, line);
        abort();
    }
#endif

    return (unsigned int)value;
}

#define PC_RUNTIME_U32_PTR(value) pc_runtime_u32_ptr_checked_at((uintptr_t)(value), #value, __FILE__, __LINE__)

#else

#define PC_RUNTIME_U32_PTR(value) ((unsigned int)(value))

#endif

#endif
