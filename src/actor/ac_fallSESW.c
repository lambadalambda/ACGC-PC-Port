#include "ac_fallSESW.h"
#include "m_name_table.h"
#include "evw_anime.h"
#include "m_common_data.h"
#include "m_lib.h"
#include "audio.h"
#include "sys_math3d.h"
#include "sys_matrix.h"
#include "m_rcp.h"

extern Gfx obj_fallSESW_model[];
extern Gfx obj_fallSE_rainbowT_model[];
extern EVW_ANIME_DATA obj_fallSE_evw_anime;

enum {
    aFLEW_AUDIO_TOKEN_BASE = 0x46450000u,
    aFLEW_AUDIO_TOKEN_INVALID = 0xFFFFu,
};

_Static_assert(BLOCK_X_NUM * UT_X_NUM * BLOCK_Z_NUM * UT_Z_NUM <= aFLEW_AUDIO_TOKEN_INVALID,
               "east waterfall audio token field must fit in 16 bits");

static u32 aFLEW_GetAudioToken(const ACTOR* actor) {
    int ut_x;
    int ut_z;

    if (mFI_Wpos2UtNum(&ut_x, &ut_z, actor->home.position)) {
        u32 ut_index = (u32)(ut_z * (BLOCK_X_NUM * UT_X_NUM) + ut_x);

        return aFLEW_AUDIO_TOKEN_BASE | ut_index;
    }

    return aFLEW_AUDIO_TOKEN_BASE | aFLEW_AUDIO_TOKEN_INVALID;
}

static void aFLEW_actor_move(ACTOR* actor, GAME* game);
static void aFLEW_actor_draw(ACTOR* actor, GAME* game);

ACTOR_PROFILE FallSESW_Profile = {
    mAc_PROFILE_FALLSESW,
    ACTOR_PART_ITEM,
    ACTOR_STATE_TA_SET,
    WATERFALL_EAST,
    ACTOR_OBJ_BANK_KEEP,
    sizeof(FALLSESW_ACTOR),
    NONE_ACTOR_PROC,
    NONE_ACTOR_PROC,
    aFLEW_actor_move,
    aFLEW_actor_draw,
    NULL,
};

#include "../src/actor/ac_fallSESW_move.c_inc"

#include "../src/actor/ac_fallSESW_draw.c_inc"
