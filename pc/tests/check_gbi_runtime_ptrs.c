#include "PR/gbi.h"
#include "libforest/gbi_extensions.h"

int main(void) {
    Gfx dl[8];
    Mtx mtx[1];
    Vtx vtx[1];
    u16 tlut[16];
    u16 tex[16];

    gSPMatrix(&dl[0], &mtx[0], G_MTX_NOPUSH | G_MTX_LOAD | G_MTX_MODELVIEW);
    gSPVertex(&dl[1], &vtx[0], 1, 0);
    gSPDisplayList(&dl[2], SEGMENT_ADDR(8, 0));
    gDPLoadTLUT_Dolphin(&dl[3], 15, 16, 1, &tlut[0]);
    gDPSetTextureImage_Dolphin(&dl[4], G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, &tex[0]);

    return (int)dl[0].words.w1;
}
