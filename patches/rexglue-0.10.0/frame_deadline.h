// SPDX-License-Identifier: GPL-3.0-only
// Opt-in host swap deadlines; original mode does not call the pacer.
#pragma once
#include <cstdint>
namespace majin::timing {
// Absolute host deadlines, with no catch-up burst after a missed deadline.
// Does not write guest clocks, registers, memory, saves or audio timestamps.
class SwapDeadline {
 public:
  uint64_t Next(uint64_t now, uint64_t frequency, uint32_t fps) {
    if (!fps || !frequency) { Reset(); return now; }
    const uint64_t period = frequency / fps ? frequency / fps : 1;
    if (!active_ || fps != fps_ || frequency != frequency_ || now < last_now_) {
      active_ = true; fps_ = fps; frequency_ = frequency;
      deadline_ = now; remainder_ = 0;
    }
    last_now_ = now;
    if (now > deadline_ && now - deadline_ >= period) {
      deadline_ = now; remainder_ = 0;
    }
    const uint64_t target = deadline_;
    deadline_ += period;
    remainder_ += frequency % fps;
    if (remainder_ >= fps) { ++deadline_; remainder_ -= fps; }
    return target > now ? target : now;
  }
  void Reset() { active_ = false; deadline_ = remainder_ = 0; }
 private:
  bool active_ = false;
  uint32_t fps_ = 0;
  uint64_t frequency_ = 0, deadline_ = 0, remainder_ = 0, last_now_ = 0;
};
} // namespace majin::timing
