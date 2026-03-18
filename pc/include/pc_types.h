#ifndef PC_TYPES_H
#define PC_TYPES_H

#include <stdint.h>

/**
 * pc_types.h - Common type definitions for the PC port layer.
 * Included automatically via pc_platform.h.
 */

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t   s8;
typedef int16_t  s16;
typedef int32_t  s32;
typedef int64_t  s64;
typedef float    f32;
typedef double   f64;
typedef int      BOOL;

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#endif /* PC_TYPES_H */
