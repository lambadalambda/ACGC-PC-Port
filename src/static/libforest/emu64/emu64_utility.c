#include "libforest/emu64/emu64.hpp"

#include "boot.h"
#include "terminal.h"
#include "MSL_C/w_math.h"
#include <stdlib.h>

#ifdef TARGET_PC
#include "pc_gx_internal.h"

/* Executable image range from pc_main.c — BSS/data can collide with N64 segments */
extern "C" uintptr_t pc_image_base;
extern "C" uintptr_t pc_image_end;

#if defined(PC_EXPERIMENTAL_64BIT)
#define PC_GBI_PTR_MAP_CAPACITY 65536u
#define PC_GBI_PTR_KEY_TAG 0xE0000000u
#define PC_GBI_PTR_KEY_MASK 0x1FFFFFFFu

typedef struct PCGbiPtrMapEntry {
    u32 key;
    uintptr_t value;
} PCGbiPtrMapEntry;

static PCGbiPtrMapEntry s_pc_gbi_ptr_map[PC_GBI_PTR_MAP_CAPACITY];

static bool pc_gbi_ptr_map_find(u32 key, uintptr_t* out_value) {
    u32 slot = key & (PC_GBI_PTR_MAP_CAPACITY - 1u);

    for (u32 n = 0; n < PC_GBI_PTR_MAP_CAPACITY; n++) {
        PCGbiPtrMapEntry* entry = &s_pc_gbi_ptr_map[slot];

        if (entry->value == 0) {
            return false;
        }
        if (entry->key == key) {
            *out_value = entry->value;
            return true;
        }

        slot = (slot + 1u) & (PC_GBI_PTR_MAP_CAPACITY - 1u);
    }

    return false;
}

static void pc_gbi_ptr_map_insert(u32 key, uintptr_t value) {
    u32 slot = key & (PC_GBI_PTR_MAP_CAPACITY - 1u);

    for (u32 n = 0; n < PC_GBI_PTR_MAP_CAPACITY; n++) {
        PCGbiPtrMapEntry* entry = &s_pc_gbi_ptr_map[slot];

        if (entry->value == 0) {
            entry->key = key;
            entry->value = value;
            return;
        }

        if (entry->key == key) {
            if (entry->value != value) {
                OSPanic(__FILE__, __LINE__, "gbi ptr key collision (%08x)", key);
                abort();
            }
            return;
        }

        slot = (slot + 1u) & (PC_GBI_PTR_MAP_CAPACITY - 1u);
    }

    OSPanic(__FILE__, __LINE__, "gbi ptr map full");
    abort();
}

static u32 pc_gbi_ptr_seed(uintptr_t value) {
    uintptr_t x = value;
    x ^= (x >> 33);
    x ^= (x >> 17);
    x ^= (x >> 9);
    return (u32)x & PC_GBI_PTR_KEY_MASK;
}

extern "C" unsigned int pc_gbi_ptr_encode(const void* ptr) {
    uintptr_t value = (uintptr_t)ptr;

    if (ptr == nullptr) {
        return 0;
    }

    u32 base = pc_gbi_ptr_seed(value);
    for (u32 n = 0; n < PC_GBI_PTR_MAP_CAPACITY; n++) {
        u32 key = PC_GBI_PTR_KEY_TAG | ((base + n) & PC_GBI_PTR_KEY_MASK);
        uintptr_t existing;

        if (pc_gbi_ptr_map_find(key, &existing)) {
            if (existing == value) {
                return key;
            }
            continue;
        }

        pc_gbi_ptr_map_insert(key, value);
        return key;
    }

    OSPanic(__FILE__, __LINE__, "gbi ptr key space exhausted");
    abort();
}

static bool pc_gbi_ptr_decode(u32 word, uintptr_t* out_value) {
    if ((word & ~PC_GBI_PTR_KEY_MASK) != PC_GBI_PTR_KEY_TAG) {
        return false;
    }

    return pc_gbi_ptr_map_find(word, out_value);
}

static bool pc_gbi_ptr_in_map_range(uintptr_t value) {
    uintptr_t begin = (uintptr_t)&s_pc_gbi_ptr_map[0];
    uintptr_t end = (uintptr_t)&s_pc_gbi_ptr_map[PC_GBI_PTR_MAP_CAPACITY];

    return value >= begin && value < end;
}

static bool pc_gbi_ptr_in_gx_state(uintptr_t value) {
    uintptr_t begin = (uintptr_t)&g_gx;
    uintptr_t end = begin + sizeof(g_gx);

    return value >= begin && value < end;
}

#else
extern "C" unsigned int pc_gbi_ptr_encode(const void* ptr) {
    return PC_RUNTIME_U32_PTR(ptr);
}

static bool pc_gbi_ptr_decode(u32 word, uintptr_t* out_value) {
    (void)word;
    (void)out_value;
    return false;
}
#endif

#ifdef _WIN32
/* Page-granularity cache for VirtualQuery results.
 * Avoids repeated syscalls for addresses in the same page. */
#define SEG2K0_PAGE_CACHE_SIZE 32
static struct {
    uintptr_t page;
    u8 committed;
    u8 valid;
} seg2k0_page_cache[SEG2K0_PAGE_CACHE_SIZE];
static int seg2k0_cache_next = 0;

static int seg2k0_is_committed(uintptr_t addr) {
    uintptr_t page = addr & ~(uintptr_t)0xFFF;
    /* Check cache first */
    for (int i = 0; i < SEG2K0_PAGE_CACHE_SIZE; i++) {
        if (seg2k0_page_cache[i].valid && seg2k0_page_cache[i].page == page) {
            return seg2k0_page_cache[i].committed;
        }
    }
    /* Cache miss — query the OS */
    MEMORY_BASIC_INFORMATION mbi;
    int committed = 0;
    if (VirtualQuery((void*)addr, &mbi, sizeof(mbi)) > 0 && mbi.State == MEM_COMMIT) {
        committed = 1;
    }
    seg2k0_page_cache[seg2k0_cache_next].page = page;
    seg2k0_page_cache[seg2k0_cache_next].committed = committed;
    seg2k0_page_cache[seg2k0_cache_next].valid = 1;
    seg2k0_cache_next = (seg2k0_cache_next + 1) % SEG2K0_PAGE_CACHE_SIZE;
    return committed;
}
#else
static int seg2k0_is_committed(uintptr_t addr) {
    (void)addr;
    return 0;
}
#endif

#if defined(PC_EXPERIMENTAL_64BIT)
static uintptr_t pc_seg2k0_arena_translate(u32 phys_addr) {
    uintptr_t arena_base = (uintptr_t)pc_os_get_arena_base();
    u32 arena_size = pc_os_get_arena_size();

    if (arena_base == 0 || phys_addr >= arena_size) {
        return 0;
    }

    return arena_base + (uintptr_t)phys_addr;
}

static void pc_seg2k0_trace(const char* tag, u32 input_addr, uintptr_t output_addr, u32 aux, uintptr_t seg0_base) {
    static u32 trace_count = 0;

    if (g_pc_verbose == 0 || trace_count >= 24) {
        return;
    }

    OSReport("[PC][seg2k0] %s in=%08x out=%p aux=%08x seg0=%p arena=%p\n", tag, input_addr, (void*)output_addr,
             aux, (void*)seg0_base, pc_os_get_arena_base());
    trace_count++;
}
#endif

uintptr_t emu64::seg2k0(u32 segadr) {
#if defined(PC_EXPERIMENTAL_64BIT)
    uintptr_t decoded;
    if (pc_gbi_ptr_decode(segadr, &decoded)) {
        if (decoded > UINT32_MAX) {
            static u32 key_decode_logged[64];
            static u32 key_decode_logged_count = 0;
            static u32 suspicious_decode_count = 0;

            if (g_pc_verbose != 0 && key_decode_logged_count < ARRAY_COUNT(key_decode_logged)) {
                bool key_seen = false;
                u32 op = 0;

                for (u32 i = 0; i < key_decode_logged_count; i++) {
                    if (key_decode_logged[i] == segadr) {
                        key_seen = true;
                        break;
                    }
                }

                if (!key_seen) {
                    int in_gx = pc_gbi_ptr_in_gx_state(decoded) ? 1 : 0;
                    int in_map = pc_gbi_ptr_in_map_range(decoded) ? 1 : 0;

                    if (this->gfx_p != nullptr) {
                        op = ((Gfx*)this->gfx_p)->words.w0 >> 24;
                    }

                    OSReport("[PC][seg2k0] key-hit key=%08x ptr=%p gx=%d map=%d gfx=%p op=%02x stack=%d\n", segadr,
                             (void*)decoded, in_gx, in_map, (void*)this->gfx_p, op, this->DL_stack_level);
                    key_decode_logged[key_decode_logged_count++] = segadr;
                }
            }

            if (pc_gbi_ptr_in_map_range(decoded) || pc_gbi_ptr_in_gx_state(decoded)) {
                if (g_pc_verbose != 0 && suspicious_decode_count < 16) {
                    OSReport("[PC][seg2k0] reject decoded key=%08x ptr=%p gfx=%p stack=%d seg0=%p\n", segadr,
                             (void*)decoded, (void*)this->gfx_p, this->DL_stack_level, (void*)this->segments[0]);
                    suspicious_decode_count++;
                }
                return 0;
            }

            return decoded;
        }
        segadr = (u32)decoded;
    } else if ((segadr & ~PC_GBI_PTR_KEY_MASK) == PC_GBI_PTR_KEY_TAG) {
        pc_seg2k0_trace("gbi-key-miss", segadr, 0, 0, this->segments[0]);
        return 0;
    }

    if (segadr >= 0x80000000u && segadr < 0xC0000000u) {
        u32 phys_addr = segadr & 0x1FFFFFFFu;
        uintptr_t translated = pc_seg2k0_arena_translate(phys_addr);

        if (translated != 0) {
            this->resolved_addresses++;
            pc_seg2k0_trace("k0", segadr, translated, phys_addr, this->segments[0]);
            return translated;
        }

        pc_seg2k0_trace("k0-unmapped", segadr, 0, phys_addr, this->segments[0]);
        return 0;
    }
#endif

    /* Addresses above the N64 segment range (upper nibble != 0)
       are direct host pointers on PC. */
    if ((segadr >> 28) != 0) {
        return (uintptr_t)segadr;
    }

#if defined(PC_EXPERIMENTAL_64BIT)
    if (segadr < 0x03000000u) {
        uintptr_t translated = pc_seg2k0_arena_translate(segadr);

        if (translated != 0) {
            this->resolved_addresses++;
            pc_seg2k0_trace("phys", segadr, translated, segadr, this->segments[0]);
            return translated;
        }

        if (this->segments[0] != 0 && this->segments[0] < 0x80000000u) {
            uintptr_t resolved = this->segments[0] + (uintptr_t)segadr;
            this->resolved_addresses++;
            pc_seg2k0_trace("phys-seg0", segadr, resolved, segadr, this->segments[0]);
            return resolved;
        }

        pc_seg2k0_trace("phys-unmapped", segadr, 0, segadr, this->segments[0]);
        return 0;
    }
#else
    /* Some display-list paths feed plain RDRAM offsets (< 0x03000000)
       instead of segmented addresses. In that case, segment 0 is the
       expected base when it is configured. */
    if (segadr < 0x03000000) {
        if (this->segments[0] != 0) {
            this->resolved_addresses++;
            return this->segments[0] + (uintptr_t)segadr;
        }
        return (uintptr_t)segadr;
    }
#endif

    /* Check if address falls within the executable image (BSS/data/code). */
    if ((uintptr_t)segadr >= pc_image_base && (uintptr_t)segadr < pc_image_end) {
        return (uintptr_t)segadr;
    }

    u32 seg = (segadr >> 24) & 0xF;
    u32 offset = segadr & 0xFFFFFF;

    if (this->segments[seg] == 0) {
#if defined(PC_EXPERIMENTAL_64BIT)
        pc_seg2k0_trace("seg-unset", segadr, 0, seg, this->segments[0]);
        return 0;
#else
        return (uintptr_t)segadr;
#endif
    }

    /* On PC, raw heap/DLL pointers can fall in the 0x03000000-0x0FFFFFFF range,
       colliding with N64 segmented addresses (seg<<24|offset). On GC, all real
       pointers had bit 31 set (k0 space) so they bypassed segment resolution.

       Strategy: try segment resolution first (this is what the game expects).
       If the resolved address is NOT in committed memory, it's likely a
       misidentification — the original address was a raw PC pointer. */
    uintptr_t resolved = this->segments[seg] + (uintptr_t)offset;

    if (seg2k0_is_committed(resolved)) {
        /* Segment resolution gave a valid address — use it (normal path) */
        this->resolved_addresses++;
        return resolved;
    }

    /* Resolved address is invalid. Check if the raw address is valid memory. */
    if (seg2k0_is_committed((uintptr_t)segadr)) {
        /* Raw address IS valid — it's a direct PC pointer misidentified as
           a segment reference. This happens when heap/stack/DLL pointers
           fall in the 0x03-0x0F range. Return as-is. */
        return (uintptr_t)segadr;
    }

    /* Neither resolved nor raw is committed. Fall through to segment resolution
       (may crash, but the VEH crash recovery will handle it). */
    this->resolved_addresses++;
    return resolved;
}
#else
uintptr_t emu64::seg2k0(u32 segadr) {
    u32 k0;

    if ((segadr >> 28) == 0) {
        if (segadr < 0x03000000) {
            this->Printf0(VT_COL(RED, WHITE) "segadr=%08x" VT_RST "\n", segadr);
            this->panic("segadr is over 0x03000000.", __FILE__, 20);
            k0 = segadr + 0x80000000;
        } else {
            k0 = this->segments[(segadr >> 24) & 0xF] + (segadr & 0xFFFFFF);
        }
        this->resolved_addresses++;
    } else {
        k0 = segadr;
    }

    if ((k0 >> 31) == 0 || k0 < 0x80000000 || k0 >= 0x83000000) {
        this->Printf0("異常なアドレスです。%08x -> %08x\n", segadr, k0);
        this->panic("異常なアドレスです。", __FILE__, 77);
        this->abnormal_addresses++;
    }

    return (uintptr_t)k0;
}
#endif

/* @unused void guMtxXFMWF(MtxP, float, float, float, float, float, float*, float*, float*, float*) */

/* @unused void guMtxXFM1F(MtxP, float, float, float, float, float*, float*, float*) */

void guMtxXFM1F_dol(MtxP mtx, float x, float y, float z, float* ox, float* oy, float* oz) {
    *ox = mtx[0][0] * x + mtx[0][1] * y + mtx[0][2] * z + mtx[0][3];
    *oy = mtx[1][0] * x + mtx[1][1] * y + mtx[1][2] * z + mtx[1][3];
    *oz = mtx[2][0] * x + mtx[2][1] * y + mtx[2][2] * z + mtx[2][3];
}

void guMtxXFM1F_dol7(MtxP mtx, float x, float y, float z, float* ox, float* oy, float* oz) {
    GC_Mtx inv;

    PSMTXInverse(mtx, inv);
    *ox = inv[0][0] * x + inv[0][1] * y + inv[0][2] * z + inv[0][3];
    *oy = inv[1][0] * x + inv[1][1] * y + inv[1][2] * z + inv[1][3];
    *oz = inv[2][0] * x + inv[2][1] * y + inv[2][2] * z + inv[2][3];
}

void guMtxXFM1F_dol2(MtxP mtx, GXProjectionType type, float x, float y, float z, float* ox, float* oy, float* oz) {
    if (type == GX_PERSPECTIVE) {
        f32 s = -1.0f / z;

        *ox = mtx[0][0] * x * s - mtx[0][2];
        *oy = mtx[1][1] * y * s - mtx[1][2];
        *oz = mtx[2][3] * s - mtx[2][2];
    } else {
        *ox = mtx[0][0] * x + mtx[0][3];
        *oy = mtx[1][1] * y + mtx[1][3];
        *oz = mtx[2][2] * z + mtx[2][3];
    }
}

void guMtxXFM1F_dol2w(MtxP mtx, GXProjectionType type, float x, float y, float z, float* ox, float* oy, float* oz,
                      float* ow) {
    if (type == GX_PERSPECTIVE) {
        *ox = mtx[0][0] * x + mtx[0][2] * z;
        *oy = mtx[1][1] * y + mtx[1][2] * z;
        *oz = mtx[2][3] + mtx[2][2] * z;
        *ow = -z;
    } else {
        *ox = mtx[0][0] * x + mtx[0][3];
        *oy = mtx[1][1] * y + mtx[1][3];
        *oz = mtx[2][2] * z + mtx[2][3];
        *ow = 1.0f;
    }
}

float guMtxXFM1F_dol3(MtxP mtx, GXProjectionType type, float z) {
    if (type == GX_PERSPECTIVE) {
        return -mtx[2][3] / (z + mtx[2][2]);
    } else {
        return (z - mtx[2][3]) / mtx[2][2];
    }
}

void guMtxXFM1F_dol6w(MtxP mtx, GXProjectionType type, float x, float y, float z, float w, float* ox, float* oy,
                      float* oz, float* ow) {
    if (type == GX_PERSPECTIVE) {
        float xScale = mtx[0][0];
        float yScale = mtx[1][1];
        float zScale = mtx[2][2];

        float xRatioScaling = mtx[0][2];
        float yRatioScaling = mtx[1][2];
        float zSkew = mtx[2][3];

        *ox = (yScale * zSkew * (x + xRatioScaling * w)) / (xScale * (yScale * zSkew));
        *oy = (xScale * zSkew * (y + yRatioScaling * w)) / (xScale * (yScale * zSkew));
        *oz = -w;
        *ow = (xScale * yScale * (z + zScale * w)) / (xScale * (yScale * zSkew));
    } else {
        float xScale = mtx[0][0];
        float xSkew = mtx[0][3];

        float yScale = mtx[1][1];
        float ySkew = mtx[1][3];

        float zScale = mtx[2][2];
        float zSkew = mtx[2][3];

        float n = 1.0f / (xScale * yScale * zScale);

        *ox = n * (yScale * zScale * (x - xSkew));
        *oy = n * (zScale * xScale * (y - ySkew));
        *oz = n * (xScale * yScale * (z - zSkew));
        *ow = 1.0f;
    }
}

void guMtxXFM1F_dol6w1(MtxP mtx, GXProjectionType type, float x, float y, float z, float w, float* ox, float* oy,
                       float* oz) {
    if (type == GX_PERSPECTIVE) {
        float xScale = mtx[0][0];
        float yScale = mtx[1][1];
        float zScale = mtx[2][2];

        float xRatioScaling = mtx[0][2];
        float yRatioScaling = mtx[1][2];
        float zSkew = mtx[2][3];

        float temp_f7 = 1.0f / (xScale * yScale * (z + (zScale * w)));

        *ox = temp_f7 * (yScale * zSkew * (x + (xRatioScaling * w)));
        *oy = temp_f7 * (xScale * zSkew * (y + (yRatioScaling * w)));
        *oz = temp_f7 * (yScale * zSkew * xScale * -w);
    } else {
        float translateX = mtx[0][3];
        float translateY = mtx[1][3];
        float translateZ = mtx[2][3];

        float scaleX = mtx[0][0];
        float scaleY = mtx[1][1];
        float scaleZ = mtx[2][2];

        *ox = (x - translateX) / scaleX;
        *oy = (y - translateY) / scaleY;
        *oz = (z - translateZ) / scaleZ;
    }
}

/* @unused void guMtxXFMWL(N64Mtx*, float, float, float, float, float*, float*, float*, float*) */

void guMtxNormalize(GC_Mtx mtx) {
    for (int i = 0; i < 3; i++) {
        float magnitude = sqrtf(mtx[i][0] * mtx[i][0] + mtx[i][1] * mtx[i][1] + mtx[i][2] * mtx[i][2]);

        mtx[i][0] *= 1.0f / magnitude;
        mtx[i][1] *= 1.0f / magnitude;
        mtx[i][2] *= 1.0f / magnitude;
    }
}

/* TODO: Mtx -> N64Mtx, GC_Mtx -> Mtx */
void N64Mtx_to_DOLMtx(const Mtx* n64, MtxP gc) {
    s16* fixed = ((s16*)n64) + 0;
    u16* frac = ((u16*)n64) + 16;
    int i;

    /* N64Mtx_to_DOLMtx conversion verified correct for LE - no diagnostic needed */

    for (i = 0; i < 4; i++) {
#ifdef TARGET_PC
        /* On little-endian, s16 pairs within each int32 are swapped.
           guMtxF2L packs first value in high 16 bits of each int32.
           s16[0] on BE reads high bits (correct), but on LE reads low bits (wrong).
           So swap indices 0<->1 and 2<->3 within each group of 4. */
        gc[0][i] = fastcast_float(&fixed[1]) + fastcast_float(&frac[1]) * (1.0f / 65536.0f);
        gc[1][i] = fastcast_float(&fixed[0]) + fastcast_float(&frac[0]) * (1.0f / 65536.0f);
        gc[2][i] = fastcast_float(&fixed[3]) + fastcast_float(&frac[3]) * (1.0f / 65536.0f);
#else
        gc[0][i] = fastcast_float(&fixed[0]) + fastcast_float(&frac[0]) * (1.0f / 65536.0f);
        gc[1][i] = fastcast_float(&fixed[1]) + fastcast_float(&frac[1]) * (1.0f / 65536.0f);
        gc[2][i] = fastcast_float(&fixed[2]) + fastcast_float(&frac[2]) * (1.0f / 65536.0f);
#endif

        fixed += 4;
        frac += 4;
    }

}

/* @unused my_guMtxL2F(MtxP, const N64Mtx*) */
