#ifndef DSPPROC_H
#define DSPPROC_H

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

extern s32 DSPSendCommands(u32* commands, u32 count);
extern u32 DSPReleaseHalt();
extern void DSPWaitFinish();
#if defined(TARGET_PC)
extern void DsetupTable(u32 arg0, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t arg4);
extern void DsyncFrame(u32 subframes, uintptr_t dspbuf_start, uintptr_t dspbuf_end);
#else
extern void DsetupTable(u32 arg0, u32 arg1, u32 arg2, u32 arg3, u32 arg4);
extern void DsyncFrame(u32 subframes, u32 dspbuf_start, u32 dspbuf_end);
#endif
extern void DwaitFrame();
extern void DiplSec(u32 arg0);
extern void DagbSec(u32 arg0);

#ifdef __cplusplus
}
#endif

#endif
