#include "jaudio_NES/cmdstack.h"
#include "jaudio_NES/playercall.h"
#include "dolphin/os.h"
#include <stddef.h>

JPorthead_ cmd_once;
JPorthead_ cmd_stay;

#define CMDSTACK_LINK_CAPACITY 512

typedef struct {
	u32* node;
	u32* next;
} JPortcmdLink_;

static JPortcmdLink_ cmd_links[CMDSTACK_LINK_CAPACITY];

static JPortcmdLink_* find_cmd_link(u32* node) {
	int i;

	for (i = 0; i < CMDSTACK_LINK_CAPACITY; i++) {
		if (cmd_links[i].node == node) {
			return &cmd_links[i];
		}
	}

	return NULL;
}

static JPortcmdLink_* alloc_cmd_link(u32* node) {
	int i;

	for (i = 0; i < CMDSTACK_LINK_CAPACITY; i++) {
		if (cmd_links[i].node == NULL) {
			cmd_links[i].node = node;
			cmd_links[i].next = NULL;
			return &cmd_links[i];
		}
	}

	return NULL;
}

static BOOL set_cmd_next(u32* node, u32* next) {
	JPortcmdLink_* link = find_cmd_link(node);

	if (link == NULL) {
		link = alloc_cmd_link(node);
		if (link == NULL) {
			return FALSE;
		}
	}

	link->next = next;
	return TRUE;
}

static u32* get_cmd_next(u32* node) {
	JPortcmdLink_* link = find_cmd_link(node);

	if (link == NULL) {
		return NULL;
	}

	return link->next;
}

static void clear_cmd_link(u32* node) {
	JPortcmdLink_* link = find_cmd_link(node);

	if (link != NULL) {
		link->node = NULL;
		link->next = NULL;
	}
}

static void reset_cmd_links(void) {
	int i;

	for (i = 0; i < CMDSTACK_LINK_CAPACITY; i++) {
		cmd_links[i].node = NULL;
		cmd_links[i].next = NULL;
	}
}

/*
 * --INFO--
 * Address:	8000E300
 * Size:	000028
 */
void Add_PortcmdOnce(u32* a1)
{
	Add_Portcmd(&cmd_once, a1);
}

/*
 * --INFO--
 * Address:	........
 * Size:	000028
 */
void Add_PortcmdStay(void)
{
	// UNUSED FUNCTION
}

/*
 * --INFO--
 * Address:	8000E340
 * Size:	000018
 */
int Set_Portcmd(int* a1, int a2, int a3)
{
	// Is this a struct? I have no idea
	a1[5] = a2;
	a1[6] = a3;
	a1[3] = 0;
	return 1;
}

/*
 * --INFO--
 * Address:	8000E360
 * Size:	000078
 */
BOOL Add_Portcmd(JPorthead_* port, u32* a2)
{
	BOOL interrupt = OSDisableInterrupts();
	u32* tail;

	if (a2[3]) {
		OSRestoreInterrupts(interrupt);
		return FALSE;
	}

	if (!set_cmd_next(a2, NULL)) {
		OSRestoreInterrupts(interrupt);
		return FALSE;
	}

	if (port->_04) {
		tail = (u32*)(uintptr_t)port->_04;
		if (!set_cmd_next(tail, a2)) {
			clear_cmd_link(a2);
			OSRestoreInterrupts(interrupt);
			return FALSE;
		}
		tail[4] = (u32)(uintptr_t)a2;
	} else {
		port->_00 = (uintptr_t)a2;
	}

	port->_04 = (uintptr_t)a2;
	a2[4]     = 0;
	a2[3]     = 1;
	OSRestoreInterrupts(interrupt);
	return TRUE;
}

/*
 * --INFO--
 * Address:	8000E3E0
 * Size:	000040
 */
static uintptr_t Get_Portcmd(JPorthead_* port)
{
	u32* a = (u32*)(uintptr_t)port->_00;
	if (a != NULL) {
		u32* next = get_cmd_next(a);
		port->_00 = (uintptr_t)next;
		if (next == NULL) {
			port->_04 = 0;
		}
		a[3] = 0;
		a[4] = 0;
		clear_cmd_link(a);
		return (uintptr_t)a;
	}

	return 0;
}

/*
 * --INFO--
 * Address:	........
 * Size:	000080
 */
void Cancel_Portcmd(void)
{
	// UNUSED FUNCTION
}

/*
 * --INFO--
 * Address:	........
 * Size:	000028
 */
void Cancel_PortcmdStay(void)
{
	// UNUSED FUNCTION
}

/*
 * --INFO--
 * Address:	8000E420
 * Size:	000050
 */
int Jac_Portcmd_Proc_Once(JPorthead_* port)
{
	uintptr_t p;
	while (1) {
		p = Get_Portcmd(port);
		if (!p) {
			break;
		}
		// Ckit ahh moment unless someone figures out what type Get_Portcmd actually returns
		((int (*)(int)) * (int*)(p + 0x14))(((int*)(uintptr_t)p)[6]);
	}
	return 0;
}

/*
 * --INFO--
 * Address:	8000E480
 * Size:	00004C
 */
int Jac_Portcmd_Proc_Stay(JPorthead_* port)
{
	uintptr_t p = port->_00;
	while (1) {
		if (!p) {
			break;
		}
		((int (*)(int)) * (int*)(p + 0x14))(((int*)(uintptr_t)p)[6]);

		p = (uintptr_t)get_cmd_next((u32*)(uintptr_t)p);
	}
	return 0;
}

/*
 * --INFO--
 * Address:	8000E4E0
 * Size:	000030
 */
static s32 Portcmd_Main(void* a)
{
	Jac_Portcmd_Proc_Once(&cmd_once);
	Jac_Portcmd_Proc_Stay(&cmd_stay);
	return 0;
}

/*
 * --INFO--
 * Address:	8000E520
 * Size:	000010
 */
void Jac_Porthead_Init(JPorthead_* port)
{
	port->_00 = 0;
	port->_04 = 0;
}

/*
 * --INFO--
 * Address:	8000E540
 * Size:	00003C
 */
void Jac_Portcmd_Init(void)
{
	Jac_Porthead_Init(&cmd_once);
	Jac_Porthead_Init(&cmd_stay);
	reset_cmd_links();
	Jac_RegisterPlayerCallback(Portcmd_Main, 0);
}

/*
 * --INFO--
 * Address:	........
 * Size:	00001C
 */
void JP_Pitch1Shot(void)
{
	// UNUSED FUNCTION
}

/*
 * --INFO--
 * Address:	........
 * Size:	00006C
 */
void JP_Start1Shot(void)
{
	// UNUSED FUNCTION
}

/*
 * --INFO--
 * Address:	........
 * Size:	00004C
 */
void JP_Stop1Shot(void)
{
	// UNUSED FUNCTION
}
