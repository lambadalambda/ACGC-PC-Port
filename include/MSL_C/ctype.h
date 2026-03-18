#ifndef _CTYPE_H
#define _CTYPE_H

#ifdef TARGET_PC
#include <ctype.h> // Conflicts can happen otherwise in certain compiler versions
#else

#include "MSL_C/locale.h"
#include "MSL_C/ctype_api.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __MWERKS__
#define MSL_CTYPE_WEAK __declspec(weak)
#else
#define MSL_CTYPE_WEAK
#endif

MSL_CTYPE_WEAK int isalpha(int __c);
MSL_CTYPE_WEAK int isdigit(int __c);
MSL_CTYPE_WEAK int isspace(int __c);
MSL_CTYPE_WEAK int isupper(int __c);
MSL_CTYPE_WEAK int isxdigit(int __c);

MSL_CTYPE_WEAK int tolower(int __c);
MSL_CTYPE_WEAK int toupper(int __c);

// added underscore to avoid naming conflicts
inline int _isalpha(int c) {
    return (int)(__ctype_map[(unsigned char)c] & __letter);
}
inline int _isdigit(int c) {
    return (int)(__ctype_map[(unsigned char)c] & __digit);
}
inline int _isspace(int c) {
    return (int)(__ctype_map[(unsigned char)c] & __whitespace);
}
inline int _isupper(int c) {
    return (int)(__ctype_map[(unsigned char)c] & __upper_case);
}
inline int _isxdigit(int c) {
    return (int)(__ctype_map[(unsigned char)c] & __hex_digit);
}
inline int _tolower(int c) {
    return (c == -1 ? -1 : (int)__lower_map[(unsigned char)c]);
}
inline int _toupper(int c) {
    return (c == -1 ? -1 : (int)__upper_map[(unsigned char)c]);
}

#ifdef __cplusplus
}
#endif

#undef MSL_CTYPE_WEAK
#endif /* !TARGET_PC */
#endif /* _CTYPE_H */
