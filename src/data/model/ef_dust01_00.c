#include "libforest/gbi_extensions.h"
#include "PR/gbi.h"
#include "evw_anime.h"
#include "c_keyframe.h"
#include "ac_npc.h"
#include "ef_effect_control.h"

#ifdef TARGET_PC
u8 ef_dust01_0[0x80] ATTRIBUTE_ALIGN(32);
#else
u8 ef_dust01_0[] ATTRIBUTE_ALIGN(32) = {
#include "assets/ef_dust01_0.inc"
};
#endif

#ifdef TARGET_PC
u8 ef_dust01_1[0x80];
#else
u8 ef_dust01_1[] = {
#include "assets/ef_dust01_1.inc"
};
#endif

#ifdef TARGET_PC
u8 ef_dust01_2[0x80];
#else
u8 ef_dust01_2[] = {
#include "assets/ef_dust01_2.inc"
};
#endif

#ifdef TARGET_PC
u8 ef_dust01_3[0x80];
#else
u8 ef_dust01_3[] = {
#include "assets/ef_dust01_3.inc"
};
#endif

#ifdef TARGET_PC
Vtx ef_dust01_00_v[0x40 / sizeof(Vtx)];
#else
Vtx ef_dust01_00_v[] = {
#include "assets/ef_dust01_00_v.inc"
};
#endif

Gfx ef_dust01_modelT[] = {
    gsSPTexture(0, 0, 0, G_TX_RENDERTILE, G_ON),
    gsDPSetRenderMode(G_RM_FOG_SHADE_A, G_RM_ZB_CLD_SURF2),
    gsDPSetCombineLERP(0, 0, 0, PRIMITIVE, TEXEL1, TEXEL0, PRIM_LOD_FRAC, TEXEL0, SHADE, 0, COMBINED, 0, COMBINED, 0,
                       PRIMITIVE, 0),
    gsDPSetTextureImage_Dolphin(G_IM_FMT_I, G_IM_SIZ_4b, 16, 16, anime_1_txt),
    gsDPSetTile_Dolphin(G_DOLPHIN_TLUT_DEFAULT_MODE, 0, 15, GX_MIRROR, GX_MIRROR, 0, 0),
    gsDPSetTextureImage_Dolphin(G_IM_FMT_I, G_IM_SIZ_4b, 16, 16, anime_2_txt),
    gsDPSetTile_Dolphin(G_DOLPHIN_TLUT_DEFAULT_MODE, 1, 15, GX_MIRROR, GX_MIRROR, 0, 0),
    gsSPLoadGeometryMode(G_ZBUFFER | G_SHADE | G_CULL_BACK | G_FOG | G_LIGHTING | G_SHADING_SMOOTH | G_DECAL_LEQUAL),
    gsSPVertex(ef_dust01_00_v, 4, 0),
    gsSPNTrianglesInit_5b(2, 0, 1, 2, 0, 3, 1, 0, 0, 0),
    gsSPEndDisplayList(),
};

Gfx ef_dust01_stew_modelT[] = {
    gsSPTexture(0, 0, 0, G_TX_RENDERTILE, G_ON),
    gsDPSetRenderMode(G_RM_FOG_SHADE_A, G_RM_ZB_CLD_SURF2),
    gsDPSetCombineLERP(0, 0, 0, PRIMITIVE, TEXEL1, TEXEL0, PRIM_LOD_FRAC, TEXEL0, 0, 0, 0, COMBINED, COMBINED, 0,
                       PRIMITIVE, 0),
    gsDPSetTextureImage_Dolphin(G_IM_FMT_I, G_IM_SIZ_4b, 16, 16, anime_1_txt),
    gsDPSetTile_Dolphin(G_DOLPHIN_TLUT_DEFAULT_MODE, 0, 15, GX_MIRROR, GX_MIRROR, 0, 0),
    gsDPSetTextureImage_Dolphin(G_IM_FMT_I, G_IM_SIZ_4b, 16, 16, anime_2_txt),
    gsDPSetTile_Dolphin(G_DOLPHIN_TLUT_DEFAULT_MODE, 1, 15, GX_MIRROR, GX_MIRROR, 0, 0),
    gsSPLoadGeometryMode(G_ZBUFFER | G_SHADE | G_CULL_BACK | G_FOG | G_LIGHTING | G_SHADING_SMOOTH | G_DECAL_LEQUAL),
    gsSPVertex(ef_dust01_00_v, 4, 0),
    gsSPNTrianglesInit_5b(2, 0, 1, 2, 0, 3, 1, 0, 0, 0),
    gsSPEndDisplayList(),
};

Gfx ef_haro01_00_modelT[] = {
    gsSPTexture(0, 0, 0, G_TX_RENDERTILE, G_ON),
    gsDPSetCombineLERP(0, 0, 0, PRIMITIVE, TEXEL1, TEXEL0, PRIM_LOD_FRAC, TEXEL0, SHADE, 0, COMBINED, 0, COMBINED, 0,
                       PRIMITIVE, 0),
    gsDPSetRenderMode(G_RM_FOG_SHADE_A, G_RM_ZB_XLU_SURF2),
    gsDPSetTextureImage_Dolphin(G_IM_FMT_I, G_IM_SIZ_4b, 16, 16, anime_1_txt),
    gsDPSetTile_Dolphin(G_DOLPHIN_TLUT_DEFAULT_MODE, 0, 15, GX_MIRROR, GX_MIRROR, 0, 0),
    gsDPSetTextureImage_Dolphin(G_IM_FMT_I, G_IM_SIZ_4b, 16, 16, anime_2_txt),
    gsDPSetTile_Dolphin(G_DOLPHIN_TLUT_DEFAULT_MODE, 1, 15, GX_MIRROR, GX_MIRROR, 0, 0),
    gsSPLoadGeometryMode(G_ZBUFFER | G_SHADE | G_CULL_BACK | G_FOG | G_LIGHTING | G_SHADING_SMOOTH | G_DECAL_LEQUAL),
    gsSPVertex(ef_dust01_00_v, 4, 0),
    gsSPNTrianglesInit_5b(2, 0, 1, 2, 0, 3, 1, 0, 0, 0),
    gsSPEndDisplayList(),
};

#if defined(TARGET_PC) && defined(PC_EXPERIMENTAL_64BIT)
void pc_patch_ef_dust01_00_models(void) {
    static int s_patched = FALSE;

    if (s_patched) {
        return;
    }

    ef_dust01_modelT[3].words.w1 = SEGMENT_ADDR(ANIME_1_TXT_SEG, 0);
    ef_dust01_modelT[5].words.w1 = SEGMENT_ADDR(ANIME_2_TXT_SEG, 0);
    ef_dust01_modelT[8].words.w1 = pc_gbi_ptr_encode(ef_dust01_00_v);

    ef_dust01_stew_modelT[3].words.w1 = SEGMENT_ADDR(ANIME_1_TXT_SEG, 0);
    ef_dust01_stew_modelT[5].words.w1 = SEGMENT_ADDR(ANIME_2_TXT_SEG, 0);
    ef_dust01_stew_modelT[8].words.w1 = pc_gbi_ptr_encode(ef_dust01_00_v);

    ef_haro01_00_modelT[3].words.w1 = SEGMENT_ADDR(ANIME_1_TXT_SEG, 0);
    ef_haro01_00_modelT[5].words.w1 = SEGMENT_ADDR(ANIME_2_TXT_SEG, 0);
    ef_haro01_00_modelT[8].words.w1 = pc_gbi_ptr_encode(ef_dust01_00_v);

    s_patched = TRUE;
}
#else
void pc_patch_ef_dust01_00_models(void) {
}
#endif
