# Multiplex Drifting
  mbcheng2,benack2,bchian3


## Features
- 5-Stage Pipeline CPU using RISCV32i instruction set architecture.
- Split L1 caches into instruction and data caches: 2 way associative with 8 lines 8 bytes each.
- L2 cache: 2 way associative with 16 lines 8 bytes each (Twice the size of the L1 caches).
- Eviction Write Buffer: Between L2 data cache and physical memory with L2 arbiter.
- Hardware Prefetcher: Between L2 cache and physical memory with L2 arbiter.

## Status
- Succesfully runs mp3-final.s, comp1.s, and comp2.s
- Fmax with Stratix V (Quartus 18.1-std): 147.62 Mhz
