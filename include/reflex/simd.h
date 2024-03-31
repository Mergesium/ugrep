/******************************************************************************\
* Copyright (c) 2016, Robert van Engelen, Genivia Inc. All rights reserved.    *
*                                                                              *
* Redistribution and use in source and binary forms, with or without           *
* modification, are permitted provided that the following conditions are met:  *
*                                                                              *
*   (1) Redistributions of source code must retain the above copyright notice, *
*       this list of conditions and the following disclaimer.                  *
*                                                                              *
*   (2) Redistributions in binary form must reproduce the above copyright      *
*       notice, this list of conditions and the following disclaimer in the    *
*       documentation and/or other materials provided with the distribution.   *
*                                                                              *
*   (3) The name of the author may not be used to endorse or promote products  *
*       derived from this software without specific prior written permission.  *
*                                                                              *
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED *
* WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF         *
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO   *
* EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,       *
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, *
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;  *
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,     *
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR      *
* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF       *
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                                   *
\******************************************************************************/

/**
@file      simd.h
@brief     RE/flex SIMD intrinsics
@author    Robert van Engelen - engelen@genivia.com
@copyright (c) 2016-2022, Robert van Engelen, Genivia Inc. All rights reserved.
@copyright (c) BSD-3 License - see LICENSE.txt
*/

#ifndef SIMD_H
#define SIMD_H

#if defined(HAVE_AVX512BW) || defined(HAVE_AVX2)
# include <immintrin.h>
#endif
#if defined(HAVE_SSE2)
# include <emmintrin.h>
#endif
#if defined(HAVE_NEON)
#if defined(__ARM_NEON__) || defined(__ARM_NEON)
# include <arm_neon.h>
#endif
#endif

#if defined(__x86_64__) || defined(_M_X64)

#ifdef _MSC_VER
# include <intrin.h>
#endif

#ifdef _MSC_VER
# define cpuidex __cpuidex
#else
# include <cpuid.h>
# define cpuidex(CPUInfo, id, subid) __cpuid_count(id, subid, CPUInfo[0], CPUInfo[1], CPUInfo[2], CPUInfo[3])
#endif

struct SIMD_caps {
  unsigned sse2: 1;       /* true if it has SSE2 */
  unsigned avx2: 1;       /* true if it has AVX2 */
  unsigned avx512_bw: 1;  /* true if it has AVX512-BW*/
};

namespace reflex {

#ifdef _MSC_VER
#pragma intrinsic(_BitScanForward)
inline uint32_t ctz(uint32_t x)
{
  unsigned long r;
  _BitScanForward(&r, x);
  return r;
}
inline uint32_t popcount(uint32_t x)
{
  return __popcnt(x);
}
#ifdef _WIN64
#pragma intrinsic(_BitScanForward64)
inline uint32_t ctzl(uint64_t x)
{
  unsigned long r;
  _BitScanForward64(&r, x);
  return r;
}
inline uint32_t popcountl(uint64_t x)
{
  return static_cast<uint32_t>(__popcnt64(x));
}
#endif
#else
inline uint32_t ctz(uint32_t x)
{
  return __builtin_ctz(x);
}
inline uint32_t ctzl(uint64_t x)
{
  return __builtin_ctzl(x);
}
inline uint32_t popcount(uint32_t x)
{
  return __builtin_popcount(x);
}
inline uint32_t popcountl(uint64_t x)
{
  return __builtin_popcountl(x);
}
#endif

// Partially count newlines in string b up to and including position e in b, updates b close to e with uncounted part
extern size_t simd_nlcount_sse2(const char*& b, const char *e);
extern size_t simd_nlcount_avx2(const char*& b, const char *e);
extern size_t simd_nlcount_avx512bw(const char*& b, const char *e);

} // namespace reflex

#elif defined(__ARM_ARCH) || defined(_M_ARM64)

struct SIMD_caps {
  unsigned neon: 1;       /* true if it has NEON instructions */
};

/* If the arch has conditional hardware support, include detection API */
#if !defined(__SOFTFP__)
#include <sys/auxv.h>
#include <asm/hwcap.h>
#endif

#endif

namespace reflex {

  // CPU Capabilities (SIMD extensions present)
  extern const struct SIMD_caps HW;
}

#endif


