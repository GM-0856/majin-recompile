// SPDX-License-Identifier: GPL-3.0-only
#include "equivalent_counter.h"
#include <cassert>
#include <iostream>
#include <limits>
int main() {
  using majin::timing::EquivalentCounter;
  for (double fps : {30., 45., 60., 120.}) {
    EquivalentCounter counter;
    uint32_t value = 0; unsigned expires = 0;
    for (unsigned frame = 1; frame <= unsigned(fps * 31); ++frame) {
      value = counter.BeforeIncrement(value, 30. / fps) + 1;
      if (value > 870 && !expires) expires = frame;
    }
    assert(expires && expires / fps >= 29 && expires / fps < 29.05);
  }
  EquivalentCounter counter;
  uint32_t value = 0;
  for (unsigned frame = 0; frame != 100; ++frame)
    value = counter.BeforeIncrement(value, .5) + 1;
  assert(value == 50);
  value = counter.BeforeIncrement(0, .5) + 1;  // Original input resets it.
  assert(value == 1);
  value = counter.BeforeIncrement(value, .5) + 1;
  assert(value == 1);
  value = counter.BeforeIncrement(value, 0) + 1; assert(value == 1);
  for (double invalid : {-1., 1e30, std::numeric_limits<double>::quiet_NaN(),
                          std::numeric_limits<double>::infinity()}) {
    counter.Reset(); assert(counter.BeforeIncrement(0, invalid) == 0);
  }
  counter.Reset(); assert(counter.BeforeIncrement(0, 8) + 1 == 8);
  counter.Reset(); assert(counter.BeforeIncrement(UINT32_MAX, 8) + 1 == 1000000);
  std::cout << "PASS: original idle duration, input reset, stalls and invalid boundaries\n";
}
