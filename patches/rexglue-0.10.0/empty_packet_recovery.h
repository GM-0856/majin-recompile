#pragma once
#include <cstdint>
#include <optional>
#include <span>
#include <algorithm>

namespace rex::audio::majin {
// Recover only an entirely zero padding packet followed immediately by an
// independently decodable XMA2 packet. Never cross input buffers or loop points.
inline std::optional<uint32_t> EmptyPacketSuccessor(
    std::span<const uint8_t> buffer, uint32_t packet_index, uint32_t loop_count) {
  constexpr uint32_t bytes = 2048, bits = bytes * 8;
  if (loop_count != 0 || buffer.size() % bytes != 0 ||
      buffer.size() / bytes < 2 || packet_index >= buffer.size() / bytes - 1) return {};
  auto current = buffer.subspan(size_t(packet_index) * bytes, bytes);
  if (!std::all_of(current.begin(), current.end(), [](uint8_t b) { return b == 0; })) return {};
  auto next = buffer.subspan(size_t(packet_index + 1) * bytes, bytes);
  if ((next[2] & 7) != 1 || (next[0] >> 2) == 0 || next[3] == 255) return {};
  uint32_t first = (((next[0] & 3) << 13) | (next[1] << 5) | (next[2] >> 3)) + 32;
  if (first + 15 > bits) return {};
  uint32_t length = 0;
  for (uint32_t i = 0; i < 15; ++i)
    length = (length << 1) | ((next[(first + i) / 8] >> (7 - (first + i) % 8)) & 1);
  if (length < 15 || length == 0x7FFF) return {};
  return (packet_index + 1) * bits + first;
}
}
