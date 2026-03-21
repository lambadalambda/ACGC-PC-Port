/* pc_aram.c - GC's 16MB auxiliary RAM, replaced with a malloc'd buffer */
#include "pc_platform.h"
#include "pc_runtime_ptr.h"

static u8* aram_base = NULL;
static u32 aram_alloc_ptr = 0;

#if defined(PC_EXPERIMENTAL_64BIT)
#define PC_ARAM_PTR_MAP_CAPACITY 65536u
#define PC_ARAM_PTR_KEY_TAG 0xD0000000u
#define PC_ARAM_PTR_KEY_MASK 0x0FFFFFFFu

typedef struct PCAramPtrMapEntry {
    u32 key;
    uintptr_t value;
} PCAramPtrMapEntry;

static PCAramPtrMapEntry s_pc_aram_ptr_map[PC_ARAM_PTR_MAP_CAPACITY];

static int pc_aram_ptr_map_find(u32 key, uintptr_t* out_value) {
    u32 slot = key & (PC_ARAM_PTR_MAP_CAPACITY - 1u);

    for (u32 n = 0; n < PC_ARAM_PTR_MAP_CAPACITY; n++) {
        PCAramPtrMapEntry* entry = &s_pc_aram_ptr_map[slot];

        if (entry->value == 0) {
            return 0;
        }
        if (entry->key == key) {
            *out_value = entry->value;
            return 1;
        }

        slot = (slot + 1u) & (PC_ARAM_PTR_MAP_CAPACITY - 1u);
    }

    return 0;
}

static void pc_aram_ptr_map_insert(u32 key, uintptr_t value) {
    u32 slot = key & (PC_ARAM_PTR_MAP_CAPACITY - 1u);

    for (u32 n = 0; n < PC_ARAM_PTR_MAP_CAPACITY; n++) {
        PCAramPtrMapEntry* entry = &s_pc_aram_ptr_map[slot];

        if (entry->value == 0) {
            entry->key = key;
            entry->value = value;
            return;
        }

        if (entry->key == key) {
            if (entry->value != value) {
                abort();
            }
            return;
        }

        slot = (slot + 1u) & (PC_ARAM_PTR_MAP_CAPACITY - 1u);
    }

    abort();
}

static u32 pc_aram_ptr_seed(uintptr_t value) {
    uintptr_t x = value;

    x ^= (x >> 33);
    x ^= (x >> 17);
    x ^= (x >> 9);
    return (u32)x & PC_ARAM_PTR_KEY_MASK;
}
#endif

u32 pc_aram_host_addr_encode(const void* ptr) {
#if defined(PC_EXPERIMENTAL_64BIT)
    uintptr_t value = (uintptr_t)ptr;

    if (ptr == NULL) {
        return 0;
    }

    if ((value & ~(uintptr_t)0xFFFFFFFFu) == 0) {
        return (u32)value;
    }

    u32 base = pc_aram_ptr_seed(value);
    for (u32 n = 0; n < PC_ARAM_PTR_MAP_CAPACITY; n++) {
        u32 key = PC_ARAM_PTR_KEY_TAG | ((base + n) & PC_ARAM_PTR_KEY_MASK);
        uintptr_t existing;

        if (pc_aram_ptr_map_find(key, &existing)) {
            if (existing == value) {
                return key;
            }
            continue;
        }

        pc_aram_ptr_map_insert(key, value);
        return key;
    }

    abort();
#else
    return PC_RUNTIME_U32_PTR(ptr);
#endif
}

void* pc_aram_host_addr_decode(u32 addr) {
#if defined(PC_EXPERIMENTAL_64BIT)
    uintptr_t value;

    if (addr == 0) {
        return NULL;
    }

    if ((addr & ~PC_ARAM_PTR_KEY_MASK) == PC_ARAM_PTR_KEY_TAG && pc_aram_ptr_map_find(addr, &value)) {
        return (void*)value;
    }
#endif

    return (void*)(uintptr_t)addr;
}

u32 ARInit(u32* stack_idx_addr, u32 length) {
    (void)stack_idx_addr; (void)length;
    if (!aram_base) {
        aram_base = (u8*)malloc(PC_ARAM_SIZE);
        if (aram_base) {
            memset(aram_base, 0, PC_ARAM_SIZE);
        }
        aram_alloc_ptr = 0;
    }
    return 0; /* offset-based, base is always 0 */
}

u8* pc_aram_get_base(void) { return aram_base; }

u32 ARGetBaseAddress(void) { return 0; }
u32 ARGetSize(void) { return PC_ARAM_SIZE; }

u32 ARAlloc(u32 size) {
    u32 aligned_size = (size + 31) & ~31; /* 32-byte align */
    if (aram_alloc_ptr + aligned_size > PC_ARAM_SIZE) {
        fprintf(stderr, "[PC/ARAM] Out of ARAM! Requested %u, used %u/%u\n",
                size, aram_alloc_ptr, PC_ARAM_SIZE);
        return 0;
    }
    u32 addr = aram_alloc_ptr;
    aram_alloc_ptr += aligned_size;
    return addr;
}

void ARFree(u32* addr) {
    (void)addr; /* bump allocator, no-op */
}

/* type 0 = MRAM→ARAM, type 1 = ARAM→MRAM. params are always (type, mram, aram). */
void ARStartDMA(u32 type, u32 mram_addr, u32 aram_addr, u32 length) {
    void* mram_ptr;

    if (!aram_base) return;
    mram_ptr = pc_aram_host_addr_decode(mram_addr);

    /* some legacy code passes (aram_base + offset) instead of just the offset */
    if (aram_addr >= PC_ARAM_SIZE) {
        uintptr_t aram_addr_bits = (uintptr_t)aram_addr;
        uintptr_t aram_base_bits = (uintptr_t)aram_base;

        if (aram_addr_bits >= aram_base_bits && aram_addr_bits - aram_base_bits < PC_ARAM_SIZE) {
            aram_addr = (u32)(aram_addr_bits - aram_base_bits);
        }
    }

    if (length > PC_ARAM_SIZE || aram_addr > PC_ARAM_SIZE - length) {
        /* OOB read: zero-fill dest so caller doesn't get garbage (cap 1MB) */
        if (type == 1 && mram_ptr != NULL && length > 0 && length <= 0x100000) {
            memset(mram_ptr, 0, length);
        }
        return;
    }

    if (type == 0) {
        memcpy(aram_base + aram_addr, mram_ptr, length);
    } else {
        memcpy(mram_ptr, aram_base + aram_addr, length);
    }
}

u32 ARGetInternalSize(void) { return PC_ARAM_SIZE; }
BOOL ARCheckInit(void) { return aram_base != NULL; }

/* ARQ - synchronous wrapper around ARStartDMA.
 * ARQPostRequest's source/dest order differs from ARStartDMA's, so we remap. */
void ARQInit(void) {}
void ARQPostRequest(void* req, u32 owner, u32 type, u32 prio,
                    u32 source, u32 dest, u32 length, void* callback) {
    if (type == 0) {
        ARStartDMA(type, source, dest, length); /* source=mram, dest=aram */
    } else {
        ARStartDMA(type, dest, source, length); /* source=aram, dest=mram — swapped */
    }
    if (callback) ((void (*)(u32))callback)(pc_aram_host_addr_encode(req));
}

void ARQFlushQueue(void) {}
