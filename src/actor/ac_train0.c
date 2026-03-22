#include "ac_train0.h"

#include "m_name_table.h"
#include "m_common_data.h"
#include "m_field_info.h"
#include "m_event.h"
#include "sys_matrix.h"
#include "m_play.h"
#include "m_rcp.h"

static void aTR0_actor_ct(ACTOR* actor, GAME* game);
static void aTR0_actor_dt(ACTOR* actor, GAME* game);
static void aTR0_actor_move(ACTOR* actor, GAME* game);
static void aTR0_actor_draw(ACTOR* actor, GAME* game);

ACTOR_PROFILE Train0_Profile = {
    mAc_PROFILE_TRAIN0,
    ACTOR_PART_ITEM,
    ACTOR_STATE_CAN_MOVE_IN_DEMO_SCENES | ACTOR_STATE_TA_SET | ACTOR_STATE_NO_MOVE_WHILE_CULLED,
    TRAIN0,
    ACTOR_OBJ_BANK_KEEP,
    sizeof(TRAIN0_ACTOR),
    &aTR0_actor_ct,
    &aTR0_actor_dt,
    &aTR0_actor_move,
    &aTR0_actor_draw,
    NULL,
};

extern cKF_Skeleton_R_c cKF_bs_r_obj_train1_1;
extern cKF_Animation_R_c cKF_ba_r_obj_train1_1;

extern Gfx obj_train1_2_model[];

#if defined(TARGET_PC) && defined(PC_EXPERIMENTAL_64BIT)
extern void pc_patch_obj_train1_1_model_display_lists(void);
extern void pc_patch_obj_train1_3_model_display_lists(void);
#endif

static void aTR0_actor_ct(ACTOR* actor, GAME* GAME) {
    TRAIN0_ACTOR* train0 = (TRAIN0_ACTOR*)actor;

#if defined(TARGET_PC) && defined(PC_EXPERIMENTAL_64BIT)
    pc_patch_obj_train1_1_model_display_lists();
    pc_patch_obj_train1_3_model_display_lists();
#endif

    cKF_SkeletonInfo_R_ct(&train0->keyframe, &cKF_bs_r_obj_train1_1, NULL, train0->work_area, train0->morph_area);
    cKF_SkeletonInfo_R_init(&train0->keyframe, train0->keyframe.skeleton, &cKF_ba_r_obj_train1_1, 1.0f, 25.0f, 1.0f,
                            0.5f, 0.0f, 1, NULL);
    cKF_SkeletonInfo_R_play(&train0->keyframe);
    train0->actor_class.cull_width = 600.0f;
    train0->actor_class.world.angle.y = DEG2SHORT_ANGLE2(90.0f);
    train0->action = 5;
    train0->arg3 = FALSE;
}

static void aTR0_actor_dt(ACTOR* actor, GAME* game) {
    TRAIN0_ACTOR* train0 = (TRAIN0_ACTOR*)actor;
    xyz_t tr_home_pos;
    GAME_PLAY* play = (GAME_PLAY*)game;
    ACTOR* engineer_p;

    tr_home_pos = train0->actor_class.home.position;
    mFI_SetFG_common(EMPTY_NO, tr_home_pos, FALSE);

    engineer_p = Actor_info_fgName_search(&play->actor_info, SP_NPC_ENGINEER, ACTOR_PART_NPC);
    if (train0->arg3 && engineer_p != NULL) {
        Actor_delete(engineer_p);
        train0->arg3 = FALSE;
    }

    cKF_SkeletonInfo_R_dt(&train0->keyframe);
    Common_Set(train_exists_flag, FALSE);
}

#include "../src/actor/ac_train0_move.c_inc"
#include "../src/actor/ac_train0_draw.c_inc"
