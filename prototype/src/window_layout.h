// SPDX-License-Identifier: GPL-3.0-only
#pragma once
#include <algorithm>
#include <cmath>

namespace majin {
struct ClientSize { int width, height; };
inline ClientSize FitWindowClient(int width, int height, int work_width,
                                 int work_height, int frame_width, int frame_height) {
  width = std::max(1, width); height = std::max(1, height);
  const int available_w = std::max(1, work_width - std::max(0, frame_width) - 16);
  const int available_h = std::max(1, work_height - std::max(0, frame_height) - 16);
  const double scale = std::min({1.0, double(available_w) / width,
                                double(available_h) / height});
  return {std::max(1, int(std::floor(width * scale))),
          std::max(1, int(std::floor(height * scale)))};
}
}
