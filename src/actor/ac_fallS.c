#include "ac_fallS.h"
#include "m_name_table.h"
#include "evw_anime.h"
#include "m_common_data.h"
#include "m_lib.h"
#include "audio.h"
#include "sys_math3d.h"
#include "sys_matrix.h"
#include "m_rcp.h"

extern Gfx obj_fallS_model[];
extern Gfx obj_fallS_rainbowT_model[];
extern EVW_ANIME_DATA obj_fallS_evw_anime;

enum {
    aFLS_AUDIO_TOKEN_BASE = 0x46530000u,
    aFLS_AUDIO_TOKEN_INVALID = 0xFFFFu,
};

_Static_assert(BLOCK_X_NUM * UT_X_NUM * BLOCK_Z_NUM * UT_Z_NUM <= aFLS_AUDIO_TOKEN_INVALID,
               "south waterfall audio token field must fit in 16 bits");

static u32 aFLS_GetAudioToken(const ACTOR* actor) {
    int ut_x;
    int ut_z;

    if (mFI_Wpos2UtNum(&ut_x, &ut_z, actor->home.position)) {
        u32 ut_index = (u32)(ut_z * (BLOCK_X_NUM * UT_X_NUM) + ut_x);

        return aFLS_AUDIO_TOKEN_BASE | ut_index;
    }

    return aFLS_AUDIO_TOKEN_BASE | aFLS_AUDIO_TOKEN_INVALID;
}

static void aFLS_actor_move(ACTOR* actor, GAME* game);
static void aFLS_actor_draw(ACTOR* actor, GAME* game);

ACTOR_PROFILE FallS_Profile = {
    mAc_PROFILE_FALLS,
    ACTOR_PART_ITEM,
    ACTOR_STATE_TA_SET,
    WATERFALL_SOUTH,
    ACTOR_OBJ_BANK_KEEP,
    sizeof(FALLS_ACTOR),
    NONE_ACTOR_PROC,
    NONE_ACTOR_PROC,
    aFLS_actor_move,
    aFLS_actor_draw,
    NULL,
};

#include "../src/actor/ac_fallS_move.c_inc"

#include "../src/actor/ac_fallS_draw.c_inc"
