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

_Static_assert(_GBI_STATIC_PTR(sContractVertices) == 0u,
               "experimental 64-bit static GBI pointers must stay zero-initialized");
_Static_assert(_GBI_STATIC_PTR(sNestedDisplayList) == 0u,
               "experimental 64-bit static display-list pointers must stay zero-initialized");
_Static_assert(mSc_STATIC_U32_PTR(sCtrlActorProfiles) == 0u,
               "experimental 64-bit static scene pointers must stay zero-initialized");

int main(void) {
    return sTextureDisplayList[0].words.w0 == 0 || sSceneData[0].misc.type == 0;
}
