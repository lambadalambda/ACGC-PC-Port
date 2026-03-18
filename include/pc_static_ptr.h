#ifndef PC_STATIC_PTR_H
#define PC_STATIC_PTR_H

/*
 * Legacy static display lists and scene tables store addresses in 32-bit
 * words. The experimental LP64 build keeps those initializers compiling by
 * using 0 instead of silently truncating host pointers.
 */
#if defined(TARGET_PC) && defined(PC_EXPERIMENTAL_64BIT)
#define PC_STATIC_U32_PTR(ptr) 0u
#elif defined(TARGET_PC)
#define PC_STATIC_U32_PTR(ptr) (unsigned int)(uintptr_t)(ptr)
#else
#define PC_STATIC_U32_PTR(ptr) (unsigned int)(ptr)
#endif

#endif
