#include <dolphin/os/OSCache.h>
#include <string.h>

#include "JSystem/JKernel/JKRArchive.h"
#include "JSystem/JKernel/JKRDecomp.h"
#include "JSystem/JKernel/JKRDvdAramRipper.h"
#include "JSystem/JKernel/JKRDvdRipper.h"
#include "JSystem/JSystem.h"
#include "JSystem/JUtility/JUTAssertion.h"

#ifdef TARGET_PC
#include "pc_bswap.h"
#define bswap32 pc_bswap32
#define bswap16 pc_bswap16

struct SDIFileEntryDisk {
    u16 mFileID;
    u16 mHash;
    u32 mFlag;
    u32 mDataOffset;
    u32 mSize;
    u32 mData;
};
static_assert(sizeof(SDIFileEntryDisk) == 0x14, "RARC SDIFileEntry disk layout must be 20 bytes");
#endif

JKRDvdArchive::JKRDvdArchive() : JKRArchive() {
}

JKRDvdArchive::JKRDvdArchive(s32 entryNum, EMountDirection mountDirection) : JKRArchive(entryNum, MOUNT_DVD) {
    mMountDirection = mountDirection;
    if (!open(entryNum)) {
        return;
    } else {
        mVolumeType = 'RARC';
        mVolumeName = &mStrTable[mDirectories->mOffset];
        sVolumeList.prepend(&mFileLoaderLink);
        mIsMounted = true;
    }
}

JKRDvdArchive::~JKRDvdArchive() {
    if (mIsMounted == true) {
        if (mArcInfoBlock) {
            SDIFileEntry* raw_file_entries = (SDIFileEntry*)((u8*)mArcInfoBlock + mArcInfoBlock->file_entry_offset);
            SDIFileEntry* fileEntries = mFileEntries;
            for (int i = 0; i < mArcInfoBlock->num_file_entries; i++) {
                if (fileEntries->mData != nullptr) {
                    JKRFreeToHeap(mHeap, fileEntries->mData);
                }
                fileEntries++;
            }

            if (mFileEntries != raw_file_entries) {
                JKRFreeToHeap(mHeap, mFileEntries);
                mFileEntries = nullptr;
            }

            JKRFreeToHeap(mHeap, mArcInfoBlock);
            mArcInfoBlock = nullptr;
        }

        if (mDvdFile) {
            delete mDvdFile;
        }

        sVolumeList.remove(&mFileLoaderLink);
        mIsMounted = false;
    }
}

#if DEBUG
CW_FORCE_STRINGS(JKRDvdArchive_cpp, __FILE__, "isMounted()", "mMountCount == 1")
#endif

bool JKRDvdArchive::open(s32 entryNum) {
    mArcInfoBlock = nullptr;
    _60 = 0;
    mDirectories = nullptr;
    mFileEntries = nullptr;
    mStrTable = nullptr;

    mDvdFile = new (JKRGetSystemHeap(), 0) JKRDvdFile(entryNum);
    if (mDvdFile == nullptr) {
        mMountMode = 0;
        return 0;
    }
    SArcHeader* mem = (SArcHeader*)JKRAllocFromSysHeap(32, 32);
    if (mem == nullptr) {
        mMountMode = 0;
    } else {
        JKRDvdToMainRam(entryNum, (u8*)mem, EXPAND_SWITCH_DECOMPRESS, 32, nullptr, JKRDvdRipper::ALLOC_DIR_TOP, 0,
                        &mCompression);

#ifdef TARGET_PC
        mem->signature = bswap32(mem->signature);
        mem->file_length = bswap32(mem->file_length);
        mem->header_length = bswap32(mem->header_length);
        mem->file_data_offset = bswap32(mem->file_data_offset);
        mem->file_data_length = bswap32(mem->file_data_length);
        mem->_14 = bswap32(mem->_14);
        mem->_18 = bswap32(mem->_18);
        mem->_1C = bswap32(mem->_1C);
#endif

        int alignment = mMountDirection == MOUNT_DIRECTION_HEAD ? 32 : -32;
        u32 alignedSize = ALIGN_NEXT(mem->file_data_offset, 32);

        mArcInfoBlock = (SArcDataInfo*)JKRAllocFromHeap(mHeap, alignedSize, alignment);
        if (mArcInfoBlock == nullptr) {
            mMountMode = 0;
        } else {
            JKRDvdToMainRam(entryNum, (u8*)mArcInfoBlock, EXPAND_SWITCH_DECOMPRESS, alignedSize, nullptr,
                            JKRDvdRipper::ALLOC_DIR_TOP, 32, nullptr);

#ifdef TARGET_PC
            mArcInfoBlock->num_nodes = bswap32(mArcInfoBlock->num_nodes);
            mArcInfoBlock->node_offset = bswap32(mArcInfoBlock->node_offset);
            mArcInfoBlock->num_file_entries = bswap32(mArcInfoBlock->num_file_entries);
            mArcInfoBlock->file_entry_offset = bswap32(mArcInfoBlock->file_entry_offset);
            mArcInfoBlock->string_table_length = bswap32(mArcInfoBlock->string_table_length);
            mArcInfoBlock->string_table_offset = bswap32(mArcInfoBlock->string_table_offset);
            mArcInfoBlock->nextFreeFileID = bswap16(mArcInfoBlock->nextFreeFileID);
#endif

            mDirectories = (SDIDirEntry*)((u8*)mArcInfoBlock + mArcInfoBlock->node_offset);
            mStrTable = (const char*)((u8*)mArcInfoBlock + mArcInfoBlock->string_table_offset);

#ifdef TARGET_PC
            for (u32 i = 0; i < mArcInfoBlock->num_nodes; i++) {
                mDirectories[i].mType = bswap32(mDirectories[i].mType);
                mDirectories[i].mOffset = bswap32(mDirectories[i].mOffset);
                mDirectories[i]._08 = bswap16(mDirectories[i]._08);
                mDirectories[i].mNum = bswap16(mDirectories[i].mNum);
                mDirectories[i].mFirstIdx = bswap32(mDirectories[i].mFirstIdx);
            }

            if (sizeof(void*) > 4) {
                /* On LP64 hosts, SDIFileEntry is wider than the 32-bit on-disk RARC entry. */
                SDIFileEntryDisk* disk_entries = (SDIFileEntryDisk*)((u8*)mArcInfoBlock + mArcInfoBlock->file_entry_offset);
                mFileEntries = (SDIFileEntry*)JKRAllocFromHeap(mHeap,
                                                               sizeof(SDIFileEntry) * mArcInfoBlock->num_file_entries,
                                                               32);
                if (mFileEntries == nullptr) {
                    mMountMode = 0;
                    goto cleanup;
                }

                for (u32 i = 0; i < mArcInfoBlock->num_file_entries; i++) {
                    mFileEntries[i].mFileID = bswap16(disk_entries[i].mFileID);
                    mFileEntries[i].mHash = bswap16(disk_entries[i].mHash);
                    mFileEntries[i].mFlag = bswap32(disk_entries[i].mFlag);
                    mFileEntries[i].mDataOffset = bswap32(disk_entries[i].mDataOffset);
                    mFileEntries[i].mSize = bswap32(disk_entries[i].mSize);
                    mFileEntries[i].mData = nullptr;
                }
            } else {
                mFileEntries = (SDIFileEntry*)((u8*)mArcInfoBlock + mArcInfoBlock->file_entry_offset);
                for (u32 i = 0; i < mArcInfoBlock->num_file_entries; i++) {
                    mFileEntries[i].mFileID = bswap16(mFileEntries[i].mFileID);
                    mFileEntries[i].mHash = bswap16(mFileEntries[i].mHash);
                    mFileEntries[i].mFlag = bswap32(mFileEntries[i].mFlag);
                    mFileEntries[i].mDataOffset = bswap32(mFileEntries[i].mDataOffset);
                    mFileEntries[i].mSize = bswap32(mFileEntries[i].mSize);
                }
            }
#else
            mFileEntries = (SDIFileEntry*)((u8*)mArcInfoBlock + mArcInfoBlock->file_entry_offset);
#endif

            _60 = mem->header_length + mem->file_data_offset;
        }
    }
cleanup:
    if (mem != nullptr) {
        JKRFreeToSysHeap(mem);
    }
#if defined(TARGET_PC)
    if (mMountMode == 0 && sizeof(void*) > 4 && mArcInfoBlock != nullptr && mFileEntries != nullptr) {
        SDIFileEntry* raw_file_entries = (SDIFileEntry*)((u8*)mArcInfoBlock + mArcInfoBlock->file_entry_offset);

        if (mFileEntries != raw_file_entries) {
            JKRFreeToHeap(mHeap, mFileEntries);
            mFileEntries = nullptr;
        }
    }
#endif
    if (mMountMode == 0) {
        JREPORTF(":::Cannot alloc memory [%s][%d]\n", __FILE__, 397); // Macro?
        if (mDvdFile != nullptr) {
            delete mDvdFile;
        }
    }
    return mMountMode != 0;
}

void* JKRDvdArchive::fetchResource(SDIFileEntry* fileEntry, u32* pSize) {
    JUT_ASSERT(isMounted());

    u32 sizeRef;
    u8* data;

    if (fileEntry->mData == nullptr) {
        int compression = JKRConvertAttrToCompressionType(fileEntry->mFlag >> 0x18);
        u32 size = fetchResource_subroutine(mEntryNum, _60 + fileEntry->mDataOffset, fileEntry->mSize, mHeap,
                                            (int)compression, mCompression, &data);

        if (pSize)
            *pSize = size;

        fileEntry->mData = data;
    } else if (pSize) {
        *pSize = fileEntry->mSize;
    }

    return fileEntry->mData;
}

void* JKRDvdArchive::fetchResource(void* data, u32 compressedSize, SDIFileEntry* fileEntry, u32* pSize,
                                   JKRExpandSwitch expandSwitch) {
    JUT_ASSERT(isMounted());

    u32 fileSize = compressedSize & -32;
    u32 alignedSize = ALIGN_NEXT(fileEntry->mSize, 32);

    if (alignedSize > fileSize) {
        alignedSize = fileSize;
    }

    if (fileEntry->mData == nullptr) {
        int compression = JKRConvertAttrToCompressionType(fileEntry->mFlag >> 0x18);
        if (expandSwitch != EXPAND_SWITCH_DECOMPRESS)
            compression = 0;
        alignedSize = fetchResource_subroutine(mEntryNum, _60 + fileEntry->mDataOffset, fileEntry->mSize, (u8*)data,
                                               fileSize, compression, mCompression);
    } else {
        JKRHeap::copyMemory(data, fileEntry->mData, alignedSize);
    }

    if (pSize) {
        *pSize = alignedSize;
    }
    return data;
}

u32 JKRDvdArchive::fetchResource_subroutine(s32 entryNum, u32 offset, u32 size, u8* data, u32 expandSize,
                                            int fileCompression, int archiveCompression) {
    u32 prevAlignedSize, alignedSize;

    alignedSize = ALIGN_NEXT(size, 32);
    prevAlignedSize = ALIGN_PREV(expandSize, 32);
    switch (archiveCompression) {
        case JKRCOMPRESSION_NONE: {
            switch (fileCompression) {
                case JKRCOMPRESSION_NONE:

                    if (alignedSize > prevAlignedSize) {
                        alignedSize = prevAlignedSize;
                    }
                    JKRDvdRipper::loadToMainRAM(entryNum, data, EXPAND_SWITCH_DEFAULT, alignedSize, nullptr,
                                                JKRDvdRipper::ALLOC_DIR_TOP, offset, nullptr);
                    return alignedSize;

                case JKRCOMPRESSION_YAY0:
                case JKRCOMPRESSION_YAZ0:
                    u8* header = (u8*)JKRAllocFromSysHeap(0x20, 0x20);
                    JKRDvdRipper::loadToMainRAM(entryNum, header, EXPAND_SWITCH_NONE, 0x20, nullptr,
                                                JKRDvdRipper::ALLOC_DIR_TOP, offset, nullptr);
                    u32 expandFileSize = JKRDecompExpandSize(header);
                    JKRFreeToSysHeap(header);
                    alignedSize = ALIGN_NEXT(expandFileSize, 32);
                    if (alignedSize > prevAlignedSize) {
                        alignedSize = prevAlignedSize;
                    }
                    JKRDvdRipper::loadToMainRAM(entryNum, data, EXPAND_SWITCH_DECOMPRESS, alignedSize, nullptr,
                                                JKRDvdRipper::ALLOC_DIR_TOP, offset, nullptr);
                    return expandFileSize;
            }
        }
        case JKRCOMPRESSION_YAZ0: {
            if (size > prevAlignedSize) {
                size = prevAlignedSize;
            }
            JKRDvdRipper::loadToMainRAM(entryNum, data, EXPAND_SWITCH_DECOMPRESS, size, nullptr,
                                        JKRDvdRipper::ALLOC_DIR_TOP, offset, nullptr);
            return size;
        }

        case JKRCOMPRESSION_YAY0: {
            JPANIC(537, "Sorry, not prepared for SZP archive.\n");
            return 0;
        }

        default: {
            JPANIC(546, ":::??? bad sequence\n");
        }
    }
    return 0;
}

u32 JKRDvdArchive::fetchResource_subroutine(s32 entryNum, u32 offset, u32 size, JKRHeap* heap, int fileCompression,
                                            int archiveCompression, u8** pBuf) {
    u32 alignedSize = ALIGN_NEXT(size, 32);

    u8* buffer;
    switch (archiveCompression) {
        case JKRCOMPRESSION_NONE: {
            switch (fileCompression) {
                case JKRCOMPRESSION_NONE:
                    buffer = (u8*)JKRAllocFromHeap(heap, alignedSize, 32);
                    JUT_ASSERT(buffer != 0);

                    JKRDvdToMainRam(entryNum, buffer, EXPAND_SWITCH_DEFAULT, alignedSize, nullptr,
                                    JKRDvdRipper::ALLOC_DIR_TOP, offset, nullptr);
                    *pBuf = buffer;
                    return alignedSize;

                case JKRCOMPRESSION_YAY0:
                case JKRCOMPRESSION_YAZ0:
                    u8* header = (u8*)JKRAllocFromHeap(heap, 0x20, 0x20);
                    JKRDvdToMainRam(entryNum, header, EXPAND_SWITCH_NONE, 0x20, nullptr, JKRDvdRipper::ALLOC_DIR_TOP,
                                    offset, nullptr);

                    alignedSize = JKRDecompExpandSize(header);
                    JKRFreeToHeap(heap, header);
                    buffer = (u8*)JKRAllocFromHeap(heap, alignedSize, 0x20);
                    JUT_ASSERT(buffer);

                    JKRDvdToMainRam(entryNum, buffer, EXPAND_SWITCH_DECOMPRESS, alignedSize, nullptr,
                                    JKRDvdRipper::ALLOC_DIR_TOP, offset, nullptr);
                    *pBuf = buffer;
                    return alignedSize;
            }
        }
        case JKRCOMPRESSION_YAZ0: {
            buffer = (u8*)JKRAllocFromHeap(heap, alignedSize, 32);
            JUT_ASSERT(buffer);
            JKRDvdToMainRam(entryNum, buffer, EXPAND_SWITCH_DECOMPRESS, size, nullptr, JKRDvdRipper::ALLOC_DIR_TOP,
                            offset, nullptr);
            *pBuf = buffer;
            return alignedSize;
        }

        case JKRCOMPRESSION_YAY0: {
            JPANIC(612, "Sorry, not prepared for SZP archive.\n");
            return 0;
        }

        default: {
            JPANIC(617, ":::??? bad sequence\n");
        }
    }
    return 0;
}
