// SPDX-License-Identifier: GPL-3.0-only
#pragma once
#include <cmath>
#include <cstdint>
namespace majin::timing {
// Feed original-rate frame equivalents into an existing incrementing counter.
// A reset by original input/state code is recognized on the next observation.
class EquivalentCounter {
 public:
  uint32_t BeforeIncrement(uint32_t observed, double original_ticks) {
    if (!active_ || observed != expected_) { value_ = observed; active_ = true; }
    if (std::isfinite(original_ticks) && original_ticks >= 0 && original_ticks <= 8)
      value_ += original_ticks;
    expected_ = uint32_t(std::fmin(1000000.0,
        std::fmax(1.0, std::floor(value_ + 1e-7))));
    return expected_ - 1;  // Original code adds one; never underflow unsigned.
  }
  void Reset() { active_ = false; value_ = 0; expected_ = 0; }
 private:
  bool active_ = false;
  double value_ = 0;
  uint32_t expected_ = 0;
};
}
