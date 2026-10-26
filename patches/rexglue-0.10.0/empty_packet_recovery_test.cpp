#include "empty_packet_recovery.h"
#include <array>
#include <cassert>
int main() {
  using rex::audio::majin::EmptyPacketSuccessor;
  std::array<uint8_t, 4096> b{};
  assert(!EmptyPacketSuccessor(b, 0, 0));
  b[2048]=4; b[2050]=1; b[2052]=0; b[2053]=64; // XMA2, first=32, frame length=32 bits
  assert(EmptyPacketSuccessor(b,0,0)==16416);
  assert(!EmptyPacketSuccessor(b,0,1));
  assert(!EmptyPacketSuccessor(b,1,0));
  assert(!EmptyPacketSuccessor(b,UINT32_MAX,0));
  b[7]=1; assert(!EmptyPacketSuccessor(b,0,0)); b[7]=0;
  b[2050]=0; assert(!EmptyPacketSuccessor(b,0,0)); b[2050]=1;
  b[2052]=255; b[2053]=254; assert(!EmptyPacketSuccessor(b,0,0));
  assert(!EmptyPacketSuccessor(std::span<const uint8_t>(b).first(4095),0,0));
}
