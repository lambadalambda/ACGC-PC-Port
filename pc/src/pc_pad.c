/* pc_pad.c - GC controller input via SDL gamepad + keyboard */
#include "pc_platform.h"
#include "pc_typing.h"
#include "pc_keybindings.h"
#include <dolphin/pad.h>
#include <stdlib.h>
#include <stdio.h>

/* analog stick constants */
#define STICK_MAGNITUDE     80
#define AXIS_DEADZONE       4000
#define TRIGGER_THRESHOLD   100
#define RUMBLE_DURATION_MS  200

static SDL_GameController* g_controller = NULL;

static int pc_pad_log_enabled(void);

static int pc_pad_parse_env_int(const char* name, int default_value) {
    const char* value = getenv(name);

    if (value == NULL || value[0] == '\0') {
        return default_value;
    }

    {
        char* end = NULL;
        long parsed = strtol(value, &end, 10);

        if (end == value || (end != NULL && end[0] != '\0')) {
            return default_value;
        }

        return (int)parsed;
    }
}

typedef struct {
    const char* name;
    const char* env_enable;
    const char* env_start;
    const char* env_every;
    const char* env_hold;
    u16 button_mask;
    int configured;
    int enabled;
    int start_frame;
    int every_frames;
    int hold_frames;
    int frame_counter;
} PCPadAutopressButton;

static int pc_pad_autopress_button_apply(PCPadAutopressButton* cfg, u16* buttons) {
    int pressed = 0;

    if (!cfg->configured) {
        const char* env = getenv(cfg->env_enable);

        cfg->enabled = (env != NULL && env[0] != '\0' && env[0] != '0') ? 1 : 0;
        cfg->start_frame = pc_pad_parse_env_int(cfg->env_start, 120);
        cfg->every_frames = pc_pad_parse_env_int(cfg->env_every, 20);
        cfg->hold_frames = pc_pad_parse_env_int(cfg->env_hold, 2);

        if (cfg->start_frame < 0) {
            cfg->start_frame = 0;
        }
        if (cfg->every_frames < 1) {
            cfg->every_frames = 1;
        }
        if (cfg->hold_frames < 1) {
            cfg->hold_frames = 1;
        }
        if (cfg->hold_frames > cfg->every_frames) {
            cfg->hold_frames = cfg->every_frames;
        }

        if (cfg->enabled && (pc_pad_log_enabled() || g_pc_verbose)) {
            printf("[PC][pad] auto %s enabled: start=%d every=%d hold=%d\n", cfg->name, cfg->start_frame,
                   cfg->every_frames, cfg->hold_frames);
        }

        cfg->configured = 1;
    }

    if (cfg->enabled) {
        int frame = cfg->frame_counter;
        if (frame >= cfg->start_frame) {
            int phase = (frame - cfg->start_frame) % cfg->every_frames;
            if (phase < cfg->hold_frames) {
                *buttons |= cfg->button_mask;
                pressed = 1;
            }
        }
    }

    cfg->frame_counter++;
    return pressed;
}

static int pc_pad_autopress_apply(u16* buttons) {
    static PCPadAutopressButton s_buttons[] = {
        { "A", "PC_AUTOPRESS_A", "PC_AUTOPRESS_A_START", "PC_AUTOPRESS_A_EVERY", "PC_AUTOPRESS_A_HOLD",
          PAD_BUTTON_A, 0, 0, 120, 20, 2, 0 },
        { "START", "PC_AUTOPRESS_START", "PC_AUTOPRESS_START_START", "PC_AUTOPRESS_START_EVERY",
          "PC_AUTOPRESS_START_HOLD", PAD_BUTTON_START, 0, 0, 120, 20, 2, 0 },
        { "DPAD_RIGHT", "PC_AUTOPRESS_DPAD_RIGHT", "PC_AUTOPRESS_DPAD_RIGHT_START", "PC_AUTOPRESS_DPAD_RIGHT_EVERY",
          "PC_AUTOPRESS_DPAD_RIGHT_HOLD", PAD_BUTTON_RIGHT, 0, 0, 120, 20, 2, 0 },
        { "DPAD_DOWN", "PC_AUTOPRESS_DPAD_DOWN", "PC_AUTOPRESS_DPAD_DOWN_START", "PC_AUTOPRESS_DPAD_DOWN_EVERY",
          "PC_AUTOPRESS_DPAD_DOWN_HOLD", PAD_BUTTON_DOWN, 0, 0, 120, 20, 2, 0 },
    };

    int any_pressed = 0;
    size_t i;
    size_t count = sizeof(s_buttons) / sizeof(s_buttons[0]);

    /* Keep this list data-driven so we can script intro-menu navigation
     * without adding one-off code paths for each new button sequence. */
    for (i = 0; i < count; i++) {
        if (pc_pad_autopress_button_apply(&s_buttons[i], buttons)) {
            any_pressed = 1;
        }
    }

    return any_pressed;
}

static int pc_pad_log_enabled(void) {
    static int enabled = -1;

    if (enabled >= 0) {
        return enabled;
    }

    {
        const char* env = getenv("PC_LOG_GAMEPAD_INPUTS");
        enabled = (env != NULL && env[0] != '\0' && env[0] != '0') ? 1 : 0;
    }

    return enabled;
}

static void pc_pad_log_state_if_changed(const char* source, u16 buttons, s8 stickX, s8 stickY, s8 cstickX, s8 cstickY,
                                        u8 lt, u8 rt) {
    static int has_prev = 0;
    static u16 prev_buttons = 0;
    static s8 prev_stickX = 0;
    static s8 prev_stickY = 0;
    static s8 prev_cstickX = 0;
    static s8 prev_cstickY = 0;
    static u8 prev_lt = 0;
    static u8 prev_rt = 0;

    if (!pc_pad_log_enabled()) {
        return;
    }

    if (has_prev && prev_buttons == buttons && prev_stickX == stickX && prev_stickY == stickY &&
        prev_cstickX == cstickX && prev_cstickY == cstickY && prev_lt == lt && prev_rt == rt) {
        return;
    }

    printf("[PC][pad] src=%s btn=0x%04X lx=%d ly=%d rx=%d ry=%d lt=%u rt=%u\n", source, buttons, (int)stickX,
           (int)stickY, (int)cstickX, (int)cstickY, (unsigned int)lt, (unsigned int)rt);

    prev_buttons = buttons;
    prev_stickX = stickX;
    prev_stickY = stickY;
    prev_cstickX = cstickX;
    prev_cstickY = cstickY;
    prev_lt = lt;
    prev_rt = rt;
    has_prev = 1;
}

BOOL PADInit(void) {
    for (int i = 0; i < SDL_NumJoysticks(); i++) {
        if (SDL_IsGameController(i)) {
            g_controller = SDL_GameControllerOpen(i);
            if (g_controller) {
                if (pc_pad_log_enabled()) {
                    printf("[PC][pad] controller opened at init: index=%d name=%s\n", i,
                           SDL_GameControllerName(g_controller));
                }
                break;
            }
        }
    }
    return TRUE;
}

u32 PADRead(PADStatus* status) {
    memset(status, 0, sizeof(PADStatus) * 4);

    const u8* keys = SDL_GetKeyboardState(NULL);
    u32 mouse = SDL_GetMouseState(NULL, NULL);
    u16 buttons = 0;
    s8 stickX = 0, stickY = 0;
    s8 cstickX = 0, cstickY = 0;
    u8 lt = 0;
    u8 rt = 0;
    const char* log_source = "keyboard";

    /* Suppress keyboard-to-button mapping when typing into the in-game text editor */
    if (!(g_pc_typing_mode && g_pc_editor_active)) {
        /* helper: check if a PCInputCode is currently pressed */
        #define INPUT_PRESSED(code) \
            (((code) & PC_INPUT_MOUSE_BIT) \
                ? (mouse & SDL_BUTTON((code) & 0xFF)) \
                : keys[(SDL_Scancode)(code)])

        /* buttons (from keybindings.ini) */
        PCKeybindings* kb = &g_pc_keybindings;
        if (INPUT_PRESSED(kb->a))     buttons |= PAD_BUTTON_A;
        if (INPUT_PRESSED(kb->b))     buttons |= PAD_BUTTON_B;
        if (INPUT_PRESSED(kb->x))     buttons |= PAD_BUTTON_X;
        if (INPUT_PRESSED(kb->y))     buttons |= PAD_BUTTON_Y;
        if (INPUT_PRESSED(kb->start)) buttons |= PAD_BUTTON_START;
        if (INPUT_PRESSED(kb->z))     buttons |= PAD_TRIGGER_Z;
        if (INPUT_PRESSED(kb->l))     buttons |= PAD_TRIGGER_L;
        if (INPUT_PRESSED(kb->r))     buttons |= PAD_TRIGGER_R;

        /* main stick */
        if (INPUT_PRESSED(kb->stick_up))    stickY += STICK_MAGNITUDE;
        if (INPUT_PRESSED(kb->stick_down))  stickY -= STICK_MAGNITUDE;
        if (INPUT_PRESSED(kb->stick_left))  stickX -= STICK_MAGNITUDE;
        if (INPUT_PRESSED(kb->stick_right)) stickX += STICK_MAGNITUDE;

        /* C-stick */
        if (INPUT_PRESSED(kb->cstick_up))    cstickY += STICK_MAGNITUDE;
        if (INPUT_PRESSED(kb->cstick_down))  cstickY -= STICK_MAGNITUDE;
        if (INPUT_PRESSED(kb->cstick_left))  cstickX -= STICK_MAGNITUDE;
        if (INPUT_PRESSED(kb->cstick_right)) cstickX += STICK_MAGNITUDE;

        /* D-pad */
        if (INPUT_PRESSED(kb->dpad_up))    buttons |= PAD_BUTTON_UP;
        if (INPUT_PRESSED(kb->dpad_down))  buttons |= PAD_BUTTON_DOWN;
        if (INPUT_PRESSED(kb->dpad_left))  buttons |= PAD_BUTTON_LEFT;
        if (INPUT_PRESSED(kb->dpad_right)) buttons |= PAD_BUTTON_RIGHT;

        #undef INPUT_PRESSED
    }

    /* hotplug */
    if (!g_controller) {
        for (int i = 0; i < SDL_NumJoysticks(); i++) {
            if (SDL_IsGameController(i)) {
                g_controller = SDL_GameControllerOpen(i);
                if (g_controller) {
                    if (pc_pad_log_enabled()) {
                        printf("[PC][pad] controller hotplug open: index=%d name=%s\n", i,
                               SDL_GameControllerName(g_controller));
                    }
                    break;
                }
            }
        }
    }

    if (g_controller) {
        if (!SDL_GameControllerGetAttached(g_controller)) {
            SDL_GameControllerClose(g_controller);
            g_controller = NULL;
            if (pc_pad_log_enabled()) {
                printf("[PC][pad] controller detached\n");
            }
        }
    }
    if (g_controller) {
        log_source = "sdl-gamecontroller";
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_A)) buttons |= PAD_BUTTON_A;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_B)) buttons |= PAD_BUTTON_B;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_X)) buttons |= PAD_BUTTON_X;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_Y)) buttons |= PAD_BUTTON_Y;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_START)) buttons |= PAD_BUTTON_START;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_BACK))  buttons |= PAD_BUTTON_START;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_LEFTSHOULDER))  buttons |= PAD_TRIGGER_L;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)) buttons |= PAD_TRIGGER_Z;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_DPAD_UP))    buttons |= PAD_BUTTON_UP;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_DPAD_DOWN))  buttons |= PAD_BUTTON_DOWN;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT))  buttons |= PAD_BUTTON_LEFT;
        if (SDL_GameControllerGetButton(g_controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT)) buttons |= PAD_BUTTON_RIGHT;

        s16 lx = SDL_GameControllerGetAxis(g_controller, SDL_CONTROLLER_AXIS_LEFTX);
        s16 ly = SDL_GameControllerGetAxis(g_controller, SDL_CONTROLLER_AXIS_LEFTY);
        if (abs(lx) > AXIS_DEADZONE) {
            int sx = lx >> 8;
            if (sx > 127) sx = 127; else if (sx < -128) sx = -128;
            stickX = (s8)sx;
        }
        if (abs(ly) > AXIS_DEADZONE) {
            int sy = -(ly >> 8);
            if (sy > 127) sy = 127; else if (sy < -128) sy = -128;
            stickY = (s8)sy;
        }

        s16 rx = SDL_GameControllerGetAxis(g_controller, SDL_CONTROLLER_AXIS_RIGHTX);
        s16 ry = SDL_GameControllerGetAxis(g_controller, SDL_CONTROLLER_AXIS_RIGHTY);
        if (abs(rx) > AXIS_DEADZONE) {
            int srx = rx >> 8;
            if (srx > 127) srx = 127; else if (srx < -128) srx = -128;
            cstickX = (s8)srx;
        }
        if (abs(ry) > AXIS_DEADZONE) {
            int sry = -(ry >> 8);
            if (sry > 127) sry = 127; else if (sry < -128) sry = -128;
            cstickY = (s8)sry;
        }

        lt = (u8)(SDL_GameControllerGetAxis(g_controller, SDL_CONTROLLER_AXIS_TRIGGERLEFT) >> 7);
        rt = (u8)(SDL_GameControllerGetAxis(g_controller, SDL_CONTROLLER_AXIS_TRIGGERRIGHT) >> 7);
        if (lt > TRIGGER_THRESHOLD) buttons |= PAD_TRIGGER_L;
        if (rt > TRIGGER_THRESHOLD) buttons |= PAD_TRIGGER_R;
    }

    if (pc_pad_autopress_apply(&buttons)) {
        log_source = "autopress";
    }

    status[0].triggerLeft = lt;
    status[0].triggerRight = rt;

    pc_pad_log_state_if_changed(log_source, buttons, stickX, stickY, cstickX, cstickY, lt, rt);

    status[0].button = buttons;
    status[0].stickX = stickX;
    status[0].stickY = stickY;
    status[0].substickX = cstickX;
    status[0].substickY = cstickY;
    status[0].err = 0; /* PAD_ERR_NONE */

    return PAD_CHAN0_BIT; /* Controller 1 connected */
}

void PADControlMotor(s32 chan, u32 command) {
    if (g_controller && chan == 0) {
        u16 intensity = (command == 1) ? 0xFFFF : 0;
        SDL_GameControllerRumble(g_controller, intensity, intensity, RUMBLE_DURATION_MS);
    }
}

void PADControlAllMotors(const u32* commands) {
    PADControlMotor(0, commands[0]);
}

void PADCleanup(void) {
    if (g_controller) {
        SDL_GameControllerClose(g_controller);
        g_controller = NULL;
    }
}

BOOL PADReset(u32 mask) { (void)mask; return TRUE; }
BOOL PADRecalibrate(u32 mask) { (void)mask; return TRUE; }
BOOL PADSync(void) { return TRUE; }
void PADSetSpec(u32 spec) { (void)spec; }
void PADSetAnalogMode(u32 mode) { (void)mode; }
/* PADClamp compiled from decomp: src/static/dolphin/pad/Padclamp.c */
BOOL PADGetType(s32 chan, u32* type) { if (type) *type = 0x09000000; return TRUE; }
