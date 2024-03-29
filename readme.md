# Multiplex Drifting
  mbcheng2,benack2,bchian3


## Features
- 5-Stage Pipeline CPU using RISCV32i instruction set architecture.
- Split L1 caches into instruction and data caches: 2 way associative with 8 lines 8 bytes each.
- L2 cache: 2 way associative with 16 lines 8 bytes each (Twice the size of the L1 caches).
- Eviction Write Buffer: Between L1 data cache and L2 cache with L1 arbiter.
- Hardware Prefetcher: Between L2 cache and physical memory with L2 arbiter.
- 2 level branch predictor with global shift register, XOR indexing, local pattern history table of 2-bit saturators, and direct mapped branch target buffer.
- Performance Counters

## Status
- Succesfully runs mp3-final.s, comp1.s, comp2.s, and comp3.s
- Fmax using Stratix III device: 158.7 Mhz
- Fmax using Stratix V 5SGXEA7N2F45C2 device: 130.7 Mhz
