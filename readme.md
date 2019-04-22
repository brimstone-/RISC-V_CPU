# Multiplex Drifting
  mbcheng2,benack2,bchian3


## Features
- 5-Stage Pipeline CPU using RISCV32i instruction set architecture.
- Split L1 caches into instruction and data caches: 2 way associative with 8 lines 8 bytes each.
- L2 cache: 2 way associative with 16 lines 8 bytes each (Twice the size of the L1 caches).
- Eviction Write Buffer: Between L1 data cache and L2 cache with L1 arbiter.
- Hardware Prefetcher: Between L2 cache and physical memory with L2 arbiter.
- Performance Counters

## Status
- Succesfully runs mp3-final.s, comp1.s, and comp2.s
- Fmax using Stratix III device: 161.89 Mhz

