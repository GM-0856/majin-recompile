#include "generated/default/majin_pch.h"
#include <rex/logging.h>
#include <atomic>

// Trace the game's API wrappers, delegating to the original generated bodies.
// Raw arguments only: do not read guest buffers or change guest state/results.
// Each operation has its own ID so concurrent entry/return lines can be paired.
#define MAJIN_TRACE_SAVE(address, operation) \
    REX_EXTERN(__imp__sub_##address); \
    REX_EXTERN(sub_##address) { \
        static std::atomic<unsigned> calls{0}; \
        const unsigned id = calls.fetch_add(1, std::memory_order_relaxed); \
        REXLOG_INFO("[Majin save] " operation " id={} enter LR={:08X} r3={:08X} r4={:08X} r5={:08X} r6={:08X} r7={:08X} r8={:08X} r9={:08X} r10={:08X}", \
                    id, uint32_t(ctx.lr), ctx.r3.u32, ctx.r4.u32, ctx.r5.u32, \
                    ctx.r6.u32, ctx.r7.u32, ctx.r8.u32, ctx.r9.u32, ctx.r10.u32); \
        __imp__sub_##address(ctx, base); \
        REXLOG_INFO("[Majin save] " operation " id={} returned={:08X}", id, ctx.r3.u32); \
    }

MAJIN_TRACE_SAVE(8267AFE0, "ContentCreateEx")
MAJIN_TRACE_SAVE(8267B070, "ContentClose")
MAJIN_TRACE_SAVE(8267B078, "ContentSetThumbnail")
MAJIN_TRACE_SAVE(8267D3E0, "SetLastNtError")
MAJIN_TRACE_SAVE(8267B510, "GetOverlappedResult")
#undef MAJIN_TRACE_SAVE

REX_EXTERN(__imp__sub_8267B6C8);
REX_EXTERN(__imp__sub_8267B190);
REX_EXTERN(sub_8267B6C8) {
    const uint32_t caller = uint32_t(ctx.lr);
    const uint32_t requested = ctx.r5.u32;
    const uint32_t bytesOut = ctx.r6.u32;
    const uint32_t overlapped = ctx.r7.u32;
    __imp__sub_8267B6C8(ctx, base);
    // SDK 0.10.0 writes synchronously, but reports STATUS_PENDING for an
    // asynchronous handle. Majin's save path then consults stale LastError
    // even after GetOverlappedResult succeeded. Report immediate completion
    // only for this caller and a fully successful, already completed write.
    if (caller == 0x821B9DF4 && ctx.r3.u32 == 0 && overlapped && requested) {
        auto probe = ctx;
        __imp__sub_8267B190(probe, base);
        const uint32_t status = REX_LOAD_U32(overlapped);
        const uint32_t written = REX_LOAD_U32(overlapped + 4);
        const bool completed = probe.r3.u32 == 997 && status == 0 && written == requested;
        REXLOG_INFO("[Majin save] write completion lastError={} status={:08X} bytes={}/{} immediate={}",
                    probe.r3.u32, status, written, requested, completed);
        if (completed) {
            if (bytesOut) REX_STORE_U32(bytesOut, written);
            ctx.r3.u64 = 1;
        }
    }
}

REX_EXTERN(__imp__sub_8267B190);
REX_EXTERN(sub_8267B190) {
    const uint32_t caller = uint32_t(ctx.lr);
    __imp__sub_8267B190(ctx, base);
    // Restrict polling diagnostics to this save state machine.
    if (caller >= 0x821B9000 && caller < 0x821BB000) {
        REXLOG_INFO("[Majin save] GetLastError LR={:08X} result={:08X}", caller, ctx.r3.u32);
    }
}

REX_EXTERN(__imp__sub_826D3C20);
REX_EXTERN(__imp__sub_822E91F8);
REX_EXTERN(__imp__sub_8236FC60);

REX_EXTERN(sub_8236FC60) {
    static std::atomic<unsigned> calls{0};
    const bool trace = calls.fetch_add(1, std::memory_order_relaxed) < 4;
    if (trace) {
        REXLOG_INFO("[Majin loading] 8236FC60 entry LR={:08X} r3={:08X}",
                    uint32_t(ctx.lr), ctx.r3.u32);
    }
    __imp__sub_8236FC60(ctx, base);
    if (trace) {
        REXLOG_INFO("[Majin loading] 8236FC60 returned r3={:08X}", ctx.r3.u32);
    }
}

REX_EXTERN(sub_822E91F8) {
    static std::atomic<unsigned> calls{0};
    if (calls.fetch_add(1, std::memory_order_relaxed) < 4) {
        const uint32_t table = REX_LOAD_U32(ctx.r3.u32);
        REXLOG_INFO("[Majin thread] LR={:08X} object={:08X} table={:08X}",
                    uint32_t(ctx.lr), ctx.r3.u32, table);
        if (table >= 0x82000000 && table <= 0x82E30000 - 44) {
            for (unsigned offset = 0; offset <= 40; offset += 4) {
                REXLOG_INFO("[Majin vtable] table={:08X} offset={} target={:08X}",
                            table, offset, REX_LOAD_U32(table + offset));
            }
        }
    }
    __imp__sub_822E91F8(ctx, base);
}

// Observe the first few calls without changing the guest registers or result.
REX_EXTERN(sub_826D3C20) {
    static std::atomic<unsigned> calls{0};
    const unsigned call = calls.fetch_add(1, std::memory_order_relaxed);
    const bool trace = call < 8;
    // Automatic original-code snapshots are intentionally disabled.
    if (trace) {
        REXLOG_INFO("[Majin trace] 826D3C20 entry: LR={:08X} r3={:08X} r1={:08X}",
                    uint32_t(ctx.lr), ctx.r3.u32, ctx.r1.u32);
        // Caller already dereferenced this object and vtable slot 48.
        const uint32_t table = REX_LOAD_U32(ctx.r3.u32);
        if (table >= 0x82000000 && table <= 0x82E30000 - 52) {
            if (table >= 0x82000004) {
                REXLOG_INFO("[Majin vtable] preceding word={:08X}", REX_LOAD_U32(table - 4));
            }
            for (unsigned offset = 0; offset <= 48; offset += 4) {
                REXLOG_INFO("[Majin vtable] table={:08X} offset={} target={:08X}",
                            table, offset, REX_LOAD_U32(table + offset));
            }
        }
    }
    __imp__sub_826D3C20(ctx, base);
    if (trace) {
        REXLOG_INFO("[Majin trace] 826D3C20 result: r3={:08X}", ctx.r3.u32);
    }
}
