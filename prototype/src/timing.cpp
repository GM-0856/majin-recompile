// SPDX-License-Identifier: GPL-3.0-only
#include "generated/default/majin_pch.h"
#include "equivalent_counter.h"
#include <rex/cvar.h>
#include <rex/logging.h>
#include <bit>
#include <cmath>

REXCVAR_DEFINE_BOOL(majin_60fps, false, "Graphics",
    "Opt-in 60 FPS test mode for the supported PAL revision");

namespace {
// Both hooks run on the verified main guest thread. Thread-local state makes
// an unexpected caller on another thread a no-op rather than sharing objects.
thread_local uint32_t main_object = 0;
constexpr uint32_t kRatio = 0x150F8, kRate = 0x15104;
bool Enabled() {
  static const bool enabled = rex::cvar::Query<bool>("majin_60fps");
  return enabled;
}
bool Span(uint32_t object, uint32_t size) {
  return object >= 0x10000 && object <= UINT32_MAX - size;
}
float ReadFloat(uint8_t* base, uint32_t address) {
  return std::bit_cast<float>(REX_LOAD_U32(address));
}
}

REX_EXTERN(__imp__sub_82162238);
REX_EXTERN(sub_82162238) {
  const uint32_t object = ctx.r3.u32;
  const bool caller = uint32_t(ctx.lr) == 0x821616EC;
  __imp__sub_82162238(ctx, base);
  if (!Enabled() || !caller || !Span(object, kRate + 4)) return;
  // Observe the engine-owned delta only. Never force its fixed/variable flag,
  // change its clocks, scale audio or alter shared constant/data pools.
  const float rate = ReadFloat(base, object + kRate);
  const float ratio = ReadFloat(base, object + kRatio);
  main_object = rate == 30.0f && std::isfinite(ratio) && ratio >= 0 && ratio <= 8
                    ? object : 0;
  static const bool announced = [] {
    REXLOG_INFO("[Majin 60 FPS] opt-in mode; engine time calculation unchanged; title idle timer normalized");
    return true;
  }();
  (void)announced;
}

REX_EXTERN(__imp__sub_821CC390);
REX_EXTERN(sub_821CC390) {
  if (!Enabled()) { __imp__sub_821CC390(ctx, base); return; }
  const uint32_t object = ctx.r3.u32;
  thread_local majin::timing::EquivalentCounter counter;
  thread_local uint32_t owner = 0;
  // SceneTitleTitle, idle state, 100-byte object in the import-validated PAL
  // revision. Original code retains all input checks and state transitions.
  if (!main_object || !Span(object, 100) ||
      REX_LOAD_U32(object) != 0x820EC3C4 ||
      REX_LOAD_U32(object + 48) != 6 || REX_LOAD_U32(object + 88) > 870) {
    counter.Reset(); owner = 0;
    __imp__sub_821CC390(ctx, base); return;
  }
  if (owner != object) { counter.Reset(); owner = object; }
  const double ratio = ReadFloat(base, main_object + kRatio);
  REX_STORE_U32(object + 88,
      counter.BeforeIncrement(REX_LOAD_U32(object + 88), ratio));
  // Do not dereference the scene after the original call: it owns its lifetime.
  // An input reset is recognized from the observed counter on the next call.
  __imp__sub_821CC390(ctx, base);
}
