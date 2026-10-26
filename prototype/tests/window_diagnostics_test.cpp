// SPDX-License-Identifier: GPL-3.0-only
#include "../src/window_layout.h"
#include "../../patches/rexglue-0.10.0/release_frame_timing.h"
#include <cstdlib>
#include <iostream>
int main() {
  int checks = 0;
  auto check = [&](bool ok) { ++checks; if (!ok) { std::cerr << "FAIL: " << checks << '\n'; std::exit(1); } };
  for (const auto& display : {majin::ClientSize{1366,728}, {1920,1040}, {2560,1400}}) {
    for (const auto& desired : {majin::ClientSize{1280,720}, {1920,1080}, {3840,2160}}) {
      const auto fit = majin::FitWindowClient(desired.width,desired.height,display.width,display.height,16,39);
      check(fit.width > 0 && fit.height > 0);
      check(fit.width + 16 <= display.width - 16);
      check(fit.height + 39 <= display.height - 16);
      check(fit.width <= desired.width && fit.height <= desired.height);
      check(std::abs(double(fit.width)/fit.height - double(desired.width)/desired.height) < .005);
    }
  }
  const auto small = majin::FitWindowClient(1280,720,2560,1400,16,39);
  check(small.width == 1280 && small.height == 720);
  const auto zero = majin::FitWindowClient(0,0,0,0,0,0);
  check(zero.width == 1 && zero.height == 1);
  majin::LiveFrameRate live;
  check(live.fps() == 0);
  live.AddInterval(0);live.AddInterval(-1);check(live.fps() == 0);
  for(int i=0;i<60;++i)live.AddInterval(16667);
  check(live.fps() == 60);
  for(int i=0;i<30;++i)live.AddInterval(33334);
  check(live.fps() == 30);
  live.AddInterval(1000000);check(live.fps() == 1);
  live.AddInterval(10000000);check(live.fps() == 0);
  for(int i=0;i<120;++i)live.AddInterval(8334);
  check(live.fps() == 120);
  std::cout << "PASS: " << checks << " window layout/live FPS checks.\n";
}
