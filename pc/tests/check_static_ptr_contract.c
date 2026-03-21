#include "PR/gbi.h"
#include "libforest/gbi_extensions.h"
#include "m_scene.h"

static Vtx sContractVertices[1];
static Gfx sNestedDisplayList[] = {
    gsSPVertex(sContractVertices, 1, 0),
    gsSPEndDisplayList(),
};
static u16 sContractTexture[8];
static Gfx sTextureDisplayList[] = {
    gsDPSetTextureImage_Dolphin(G_IM_FMT_RGBA, G_IM_SIZ_16b, 2, 2, sContractTexture),
    gsSPDisplayList(sNestedDisplayList),
    gsSPEndDisplayList(),
};
static s16 sCtrlActorProfiles[1];
static Scene_Word_u sSceneData[] = {
    mSc_DATA_CTRL_ACTORS(1, sCtrlActorProfiles),
    mSc_DATA_END(),
};

_Static_assert(sizeof(Gfx) == 8, "Gfx must remain 64-bit command words");
_Static_assert(sizeof(TexRect) == 16, "TexRect must remain 128-bit command payload");
_Static_assert(sizeof(Mtx) == 64, "Mtx must remain 4x4 s15.16 words (64 bytes)");
_Static_assert(sizeof(Hilite) == 16, "Hilite must remain 16 bytes");

#if defined(TARGET_PC) && defined(PC_EXPERIMENTAL_64BIT)
_Static_assert(_GBI_STATIC_PTR(sContractVertices) == 0u,
               "LP64 static GBI pointers must use zero placeholder words");
_Static_assert(_GBI_STATIC_PTR(sNestedDisplayList) == 0u,
               "LP64 static display-list pointers must use zero placeholder words");
_Static_assert(mSc_STATIC_U32_PTR(sCtrlActorProfiles) == 0u,
               "LP64 static scene pointers must use zero placeholder words");
_Static_assert(ALIGN_NEXT((uintptr_t)0x100000001ULL, (u32)32u) == (uintptr_t)0x100000020ULL,
               "ALIGN_NEXT must preserve upper address bits on LP64");
_Static_assert(ALIGN_PREV((uintptr_t)0x10000001FULL, (u32)32u) == (uintptr_t)0x100000000ULL,
               "ALIGN_PREV must preserve upper address bits on LP64");
#else
_Static_assert(_GBI_STATIC_PTR(sContractVertices) == (unsigned int)(uintptr_t)sContractVertices,
               "static GBI pointers must preserve low 32-bit address word");
_Static_assert(_GBI_STATIC_PTR(sNestedDisplayList) == (unsigned int)(uintptr_t)sNestedDisplayList,
               "static display-list pointers must preserve low 32-bit address word");
_Static_assert(mSc_STATIC_U32_PTR(sCtrlActorProfiles) == (unsigned int)(uintptr_t)sCtrlActorProfiles,
               "static scene pointers must preserve low 32-bit address word");
#endif

int main(void) {
    return sTextureDisplayList[0].words.w0 == 0 || sSceneData[0].misc.type == 0;
}
