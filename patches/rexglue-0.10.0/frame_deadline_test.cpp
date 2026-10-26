#include "frame_deadline.h"
#include <cassert>
#include <iostream>
int main() {
  using majin::timing::SwapDeadline;
  SwapDeadline p;
  assert(p.Next(100,10000000,0)==100);
  assert(p.Next(200,0,60)==200);
  assert(p.Next(1000000,10000000,60)==1000000);
  assert(p.Next(1000000,10000000,60)==1166666);
  assert(p.Next(1000000,10000000,60)==1333333);
  // Repeated early calls preserve the rational remainder exactly.
  p.Reset();p.Next(0,10000000,60);
  for(unsigned i=1;i<=3600;++i) assert(p.Next(0,10000000,60)==uint64_t(i)*10000000/60);
  // Missed frames reset, avoiding a catch-up burst and artificial fast-forward.
  assert(p.Next(1000000000,10000000,60)==1000000000);
  assert(p.Next(1000000000,10000000,60)==1000166666);
  assert(p.Next(500,10000000,60)==500); // time rollback
  assert(p.Next(500,10000000,30)==500); // mode change
  assert(p.Next(500,10000000,30)==333833);
  assert(p.Next(600,10000000,0)==600);
  assert(p.Next(600,10000000,60)==600);
  assert(p.Next(600,1,120)==600);
  assert(p.Next(600,1,120)>=601);
  std::cout << "PASS: 3616 deadline/rational cadence/reset/stall/disabled boundary assertions\n";
}
