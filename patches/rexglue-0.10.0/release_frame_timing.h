// SPDX-License-Identifier: GPL-3.0-only
#pragma once
#include <cstdint>

namespace majin {
// A completed window of at least one second, including stalls. UI reads the
// result through the SDK's existing atomic snapshot counter, never this object.
class LiveFrameRate {
 public:
  void AddInterval(int64_t microseconds) {
    if (microseconds <= 0) return;
    elapsed_us_ += static_cast<uint64_t>(microseconds);
    ++frames_;
    if (elapsed_us_ >= 1000000) {
      fps_ = (frames_ * 1000000 + elapsed_us_ / 2) / elapsed_us_;
      elapsed_us_ = 0;
      frames_ = 0;
    }
  }
  int64_t fps() const { return static_cast<int64_t>(fps_); }
 private:
  uint64_t elapsed_us_ = 0, frames_ = 0, fps_ = 0;
};
}
