# ===========================================================================
#          https://www.gnu.org/software/autoconf-archive/ax_ext.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_EXT
#
# DESCRIPTION
#
#   Find supported SIMD extensions by requesting cpuid. When a SIMD
#   extension is found, the -m"simdextensionname" is added to SIMD_FLAGS if
#   compiler supports it. For example, if "sse2" is available then "-msse2"
#   is added to SIMD_FLAGS.
#
#   Find other supported CPU extensions by requesting cpuid. When a
#   processor extension is found, the -m"extensionname" is added to
#   CPUEXT_FLAGS if compiler supports it. For example, if "bmi2" is
#   available then "-mbmi2" is added to CPUEXT_FLAGS.
#
#   This macro calls:
#
#     AC_SUBST(SIMD_FLAGS)
#     AC_SUBST(SIMD_FLAGS_SSE2)
#     AC_SUBST(SIMD_FLAGS_AVX2)
#     AC_SUBST(SIMD_FLAGS_AVX512BW)
#     AC_SUBST(SIMD_FLAGS_NEON)
#     AC_SUBST(CPUEXT_FLAGS)
#
#   And defines:
#
#     HAVE_RDRND / HAVE_BMI1 / HAVE_BMI2 / HAVE_ADX / HAVE_MPX
#     HAVE_PREFETCHWT1 / HAVE_ABM / HAVE_MMX / HAVE_SSE / HAVE_SSE2
#     HAVE_SSE3 / HAVE_SSSE3 / HAVE_SSE4_1 / HAVE_SSE4_2 / HAVE_SSE4a
#     HAVE_SHA / HAVE_AES / HAVE_AVX / HAVE_FMA3 / HAVE_FMA4 / HAVE_XOP
#     HAVE_AVX2 / HAVE_AVX512_F / HAVE_AVX512_CD / HAVE_AVX512_PF
#     HAVE_AVX512_ER / HAVE_AVX512_VL / HAVE_AVX512_BW / HAVE_AVX512_DQ
#     HAVE_AVX512_IFMA / HAVE_AVX512_VBMI / HAVE_ALTIVEC / HAVE_VSX
#     HAVE_NEON
#
# LICENSE
#
#   Copyright (c) 2007 Christophe Tournayre <turn3r@users.sourceforge.net>
#   Copyright (c) 2013,2015 Michael Petch <mpetch@capp-sysware.com>
#   Copyright (c) 2017 Rafael de Lucena Valle <rafaeldelucena@gmail.com>
#   Copyright (c) 2024 Radu Hociung <radu.git@Mergesium.com>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved. This file is offered as-is, without any
#   warranty.

#serial 19

AC_DEFUN([AX_EXT],
[
  AC_REQUIRE([AC_CANONICAL_HOST])
  AC_REQUIRE([AC_PROG_CC])

  CPUEXT_FLAGS=""
  SIMD_FLAGS=""

  case $host_cpu in
    powerpc*)
      AC_CACHE_CHECK([whether altivec is supported for old distros], [ax_cv_have_altivec_old_ext],
          [
            if test `/usr/sbin/sysctl -a 2>/dev/null| grep -c hw.optional.altivec` != 0; then
                if test `/usr/sbin/sysctl -n hw.optional.altivec` = 1; then
                  ax_cv_have_altivec_old_ext=yes
                fi
            fi
          ])

          if test "$ax_cv_have_altivec_old_ext" = yes; then
            AC_DEFINE(HAVE_ALTIVEC,,[Support Altivec instructions])
            AX_CHECK_COMPILE_FLAG(-faltivec, SIMD_FLAGS="$SIMD_FLAGS -faltivec", [])
          fi

      AC_CACHE_CHECK([whether altivec is supported], [ax_cv_have_altivec_ext],
          [
            if test `LD_SHOW_AUXV=1 /bin/true 2>/dev/null|grep -c altivec` != 0; then
              ax_cv_have_altivec_ext=yes
            fi
          ])

          if test "$ax_cv_have_altivec_ext" = yes; then
            AC_DEFINE(HAVE_ALTIVEC,,[Support Altivec instructions])
            AX_CHECK_COMPILE_FLAG(-maltivec, SIMD_FLAGS="$SIMD_FLAGS -maltivec", [])
          fi

      AC_CACHE_CHECK([whether vsx is supported], [ax_cv_have_vsx_ext],
          [
            if test `LD_SHOW_AUXV=1 /bin/true 2>/dev/null|grep -c vsx` != 0; then
                ax_cv_have_vsx_ext=yes
            fi
          ])

          if test "$ax_cv_have_vsx_ext" = yes; then
            AC_DEFINE(HAVE_VSX,,[Support VSX instructions])
            AX_CHECK_COMPILE_FLAG(-mvsx, SIMD_FLAGS="$SIMD_FLAGS -mvsx", [])
          fi
    ;;

    arm)
      for ac_instr_info dnl
      in "neon;neon;NEON;-;-mfpu=neon;HAVE_NEON;SIMD_FLAGS_NEON" dnl
         #
      do ac_instr_os_support=$(eval echo \$ax_cv_have_$(echo $ac_instr_info | cut -d ";" -f 1)_os_support_ext)
        ac_instr_acvar=$(echo $ac_instr_info | cut -d ";" -f 2)
        ac_instr_shortname=$(echo $ac_instr_info | cut -d ";" -f 3)
        # ac_instr_chk_loc=$(echo $ac_instr_info | cut -d ";" -f 4)
        # ac_instr_chk_reg=0x$(eval echo \$$(echo $ac_instr_chk_loc | cut -d "," -f 1))
        # ac_instr_chk_bit=$(echo $ac_instr_chk_loc | cut -d "," -f 2)
        ac_instr_compiler_flags=$(echo $ac_instr_info | cut -d ";" -f 5)
        ac_instr_have_define=$(echo $ac_instr_info | cut -d ";" -f 6)
        ac_instr_flag_type=$(echo $ac_instr_info | cut -d ";" -f 7)

        AX_CHECK_COMPILE_FLAG(${ac_instr_compiler_flags}, eval ax_cv_support_${ac_instr_acvar}_ext=yes,
                                                          eval ax_cv_support_${ac_instr_acvar}_ext=no)
        if test x"$(eval echo \$ax_cv_support_${ac_instr_acvar}_ext)" = x"yes"; then
          eval ${ac_instr_flag_type}=\"\$${ac_instr_flag_type} ${ac_instr_compiler_flags}\"
          AC_DEFINE_UNQUOTED([${ac_instr_have_define}])
        else
          AC_MSG_WARN([Your compiler does not support ${ac_instr_shortname} instructions, can you try another compiler?])
        fi
      done
    ;;

    aarch64)
      for ac_instr_info dnl
      in "neon;neon;NEON;-;-march=armv8-a;HAVE_NEON;SIMD_FLAGS_NEON" dnl
         #
      do ac_instr_os_support=$(eval echo \$ax_cv_have_$(echo $ac_instr_info | cut -d ";" -f 1)_os_support_ext)
        ac_instr_acvar=$(echo $ac_instr_info | cut -d ";" -f 2)
        ac_instr_shortname=$(echo $ac_instr_info | cut -d ";" -f 3)
        # ac_instr_chk_loc=$(echo $ac_instr_info | cut -d ";" -f 4)
        # ac_instr_chk_reg=0x$(eval echo \$$(echo $ac_instr_chk_loc | cut -d "," -f 1))
        # ac_instr_chk_bit=$(echo $ac_instr_chk_loc | cut -d "," -f 2)
        ac_instr_compiler_flags=$(echo $ac_instr_info | cut -d ";" -f 5)
        ac_instr_have_define=$(echo $ac_instr_info | cut -d ";" -f 6)
        ac_instr_flag_type=$(echo $ac_instr_info | cut -d ";" -f 7)

        # No need to check compiler. arm8 is required to support NEON
        eval ${ac_instr_flag_type}=\"\$${ac_instr_flag_type} ${ac_instr_compiler_flags}\"
        eval ax_cv_support_${ac_instr_acvar}_ext=yes
        AC_DEFINE_UNQUOTED([${ac_instr_have_define}])
      done
    ;;

    i[[3456]]86*|x86_64*|amd64*)

      AC_REQUIRE([AX_GCC_X86_CPUID])
      AC_REQUIRE([AX_GCC_X86_CPUID_COUNT])
      AC_REQUIRE([AX_GCC_X86_AVX_XGETBV])

      eax_cpuid0=0
      AX_GCC_X86_CPUID(0x00000000)
      if test "$ax_cv_gcc_x86_cpuid_0x00000000" != "unknown";
      then
        eax_cpuid0=`echo $ax_cv_gcc_x86_cpuid_0x00000000 | cut -d ":" -f 1`
      fi

      eax_cpuid80000000=0
      AX_GCC_X86_CPUID(0x80000000)
      if test "$ax_cv_gcc_x86_cpuid_0x80000000" != "unknown";
      then
        eax_cpuid80000000=`echo $ax_cv_gcc_x86_cpuid_0x80000000 | cut -d ":" -f 1`
      fi

      ecx_cpuid1=0
      edx_cpuid1=0
      if test "$((0x$eax_cpuid0))" -ge 1 ; then
        AX_GCC_X86_CPUID(0x00000001)
        if test "$ax_cv_gcc_x86_cpuid_0x00000001" != "unknown";
        then
          ecx_cpuid1=`echo $ax_cv_gcc_x86_cpuid_0x00000001 | cut -d ":" -f 3`
          edx_cpuid1=`echo $ax_cv_gcc_x86_cpuid_0x00000001 | cut -d ":" -f 4`
        fi
      fi

      ebx_cpuid7=0
      ecx_cpuid7=0
      if test "$((0x$eax_cpuid0))" -ge 7 ; then
        AX_GCC_X86_CPUID_COUNT(0x00000007, 0x00)
        if test "$ax_cv_gcc_x86_cpuid_0x00000007" != "unknown";
        then
          ebx_cpuid7=`echo $ax_cv_gcc_x86_cpuid_0x00000007 | cut -d ":" -f 2`
          ecx_cpuid7=`echo $ax_cv_gcc_x86_cpuid_0x00000007 | cut -d ":" -f 3`
        fi
      fi

      ecx_cpuid80000001=0
      edx_cpuid80000001=0
      if test "$((0x$eax_cpuid80000000))" -ge "$((0x80000001))" ; then
        AX_GCC_X86_CPUID(0x80000001)
        if test "$ax_cv_gcc_x86_cpuid_0x80000001" != "unknown";
        then
          ecx_cpuid80000001=`echo $ax_cv_gcc_x86_cpuid_0x80000001 | cut -d ":" -f 3`
          edx_cpuid80000001=`echo $ax_cv_gcc_x86_cpuid_0x80000001 | cut -d ":" -f 4`
        fi
      fi

      AC_CACHE_VAL([ax_cv_have_mmx_os_support_ext],
      [
        ax_cv_have_mmx_os_support_ext=yes
      ])

      ax_cv_have_none_os_support_ext=yes

      AC_CACHE_VAL([ax_cv_have_sse_os_support_ext],
      [
        ax_cv_have_sse_os_support_ext=no,
        if test "$((0x$edx_cpuid1>>25&0x01))" = 1; then
          AC_LANG_PUSH([C])
          AC_RUN_IFELSE([AC_LANG_SOURCE([[
#include <signal.h>
#include <stdlib.h>
            /* No way at ring1 to ring3 in protected mode to check the CR0 and CR4
               control registers directly. Execute an SSE instruction.
               If it raises SIGILL then OS doesn't support SSE based instructions */
            void sig_handler(int signum){ exit(1); }
            int main(void){
              signal(SIGILL, sig_handler);
              /* SSE instruction xorps  %xmm0,%xmm0 */
              __asm__ __volatile__ (".byte 0x0f, 0x57, 0xc0");
              return 0;
            }]])],
            [ax_cv_have_sse_os_support_ext=yes],
            [ax_cv_have_sse_os_support_ext=no],
            [ax_cv_have_sse_os_support_ext=no])
          AC_LANG_POP([C])
        fi
      ])

      xgetbv_eax=0
      if test "$((0x$ecx_cpuid1>>28&0x01))" = 1; then
        AX_GCC_X86_AVX_XGETBV(0x00000000)

        if test x"$ax_cv_gcc_x86_avx_xgetbv_0x00000000" != x"unknown"; then
          xgetbv_eax=`echo $ax_cv_gcc_x86_avx_xgetbv_0x00000000 | cut -d ":" -f 1`
        fi

        AC_CACHE_VAL([ax_cv_have_avx_os_support_ext],
        [
          ax_cv_have_avx_os_support_ext=no
          if test "$((0x$ecx_cpuid1>>27&0x01))" = 1; then
            if test "$((0x$xgetbv_eax&0x6))" = 6; then
              ax_cv_have_avx_os_support_ext=yes
            fi
          fi
        ])
      fi

      AC_CACHE_VAL([ax_cv_have_avx512_os_support_ext],
      [
        ax_cv_have_avx512_os_support_ext=no
        if test "$ax_cv_have_avx_os_support_ext" = yes; then
          if test "$((0x$xgetbv_eax&0xe6))" = "$((0xe6))"; then
            ax_cv_have_avx512_os_support_ext=yes
          fi
        fi
      ])

      # This is an abridged list with only the features this project need
      # For the full list supported, see the source at the URL in the header
      # This copy was made from git 5a42398
      for ac_instr_info dnl
      in "sse;sse2;SSE2;edx_cpuid1,26;-msse2;HAVE_SSE2;SIMD_FLAGS_SSE2" dnl
         "avx;avx2;AVX2;ebx_cpuid7,5;-mavx2;HAVE_AVX2;SIMD_FLAGS_AVX2" dnl
         "avx512;avx512bw;AVX512-BW;ebx_cpuid7,30;-mavx512bw;HAVE_AVX512_BW;SIMD_FLAGS_AVX512BW" dnl
         #
      do ac_instr_os_support=$(eval echo \$ax_cv_have_$(echo $ac_instr_info | cut -d ";" -f 1)_os_support_ext)
         ac_instr_acvar=$(echo $ac_instr_info | cut -d ";" -f 2)
         ac_instr_shortname=$(echo $ac_instr_info | cut -d ";" -f 3)
         ac_instr_chk_loc=$(echo $ac_instr_info | cut -d ";" -f 4)
         ac_instr_chk_reg=0x$(eval echo \$$(echo $ac_instr_chk_loc | cut -d "," -f 1))
         ac_instr_chk_bit=$(echo $ac_instr_chk_loc | cut -d "," -f 2)
         ac_instr_compiler_flags=$(echo $ac_instr_info | cut -d ";" -f 5)
         ac_instr_have_define=$(echo $ac_instr_info | cut -d ";" -f 6)
         ac_instr_flag_type=$(echo $ac_instr_info | cut -d ";" -f 7)

         AC_CACHE_CHECK([whether ${ac_instr_shortname} is supported by the processor], [ax_cv_have_${ac_instr_acvar}_cpu_ext],
         [
           eval ax_cv_have_${ac_instr_acvar}_cpu_ext=no
           if test "$((${ac_instr_chk_reg}>>${ac_instr_chk_bit}&0x01))" = 1 ; then
             eval ax_cv_have_${ac_instr_acvar}_cpu_ext=yes
           fi
         ])

         if test x"$(eval echo \$ax_cv_have_${ac_instr_acvar}_cpu_ext)" = x"yes"; then
           AC_CACHE_CHECK([whether ${ac_instr_shortname} is supported by the processor and OS], [ax_cv_have_${ac_instr_acvar}_ext],
           [
             eval ax_cv_have_${ac_instr_acvar}_ext=no
             if test x"${ac_instr_os_support}" = x"yes"; then
               eval ax_cv_have_${ac_instr_acvar}_ext=yes
             fi
           ])

           if test "$(eval echo \$ax_cv_have_${ac_instr_acvar}_ext)" = yes; then
             AX_CHECK_COMPILE_FLAG(${ac_instr_compiler_flags}, eval ax_cv_support_${ac_instr_acvar}_ext=yes,
                                                               eval ax_cv_support_${ac_instr_acvar}_ext=no)
             if test x"$(eval echo \$ax_cv_support_${ac_instr_acvar}_ext)" = x"yes"; then
               eval ${ac_instr_flag_type}=\"\$${ac_instr_flag_type} ${ac_instr_compiler_flags}\"
               SIMD_FLAGS="${SIMD_FLAGS} ${ac_instr_compiler_flags}"
               AC_DEFINE_UNQUOTED([${ac_instr_have_define}])
             else
               AC_MSG_WARN([Your processor and OS supports ${ac_instr_shortname} instructions but not your compiler, can you try another compiler?])
             fi
           else
             if test x"${ac_instr_os_support}" = x"no"; then
               AC_CACHE_VAL(ax_cv_support_${ac_instr_acvar}_ext, eval ax_cv_support_${ac_instr_acvar}_ext=no)
               AC_MSG_WARN([Your processor supports ${ac_instr_shortname}, but your OS doesn't])
             fi
           fi
         else
           AC_CACHE_VAL(ax_cv_have_${ac_instr_acvar}_ext, eval ax_cv_have_${ac_instr_acvar}_ext=no)
           AC_CACHE_VAL(ax_cv_support_${ac_instr_acvar}_ext, eval ax_cv_support_${ac_instr_acvar}_ext=no)
         fi
      done
  ;;
  esac

  AH_TEMPLATE([HAVE_RDRND],[Define to 1 to support Digital Random Number Generator])
  AH_TEMPLATE([HAVE_BMI1],[Define to 1 to support Bit Manipulation Instruction Set 1])
  AH_TEMPLATE([HAVE_BMI2],[Define to 1 to support Bit Manipulation Instruction Set 2])
  AH_TEMPLATE([HAVE_ADX],[Define to 1 to support Multi-Precision Add-Carry Instruction Extensions])
  AH_TEMPLATE([HAVE_MPX],[Define to 1 to support Memory Protection Extensions])
  AH_TEMPLATE([HAVE_PREFETCHWT1],[Define to 1 to support Prefetch Vector Data Into Caches WT1])
  AH_TEMPLATE([HAVE_ABM],[Define to 1 to support Advanced Bit Manipulation])
  AH_TEMPLATE([HAVE_MMX],[Define to 1 to support Multimedia Extensions])
  AH_TEMPLATE([HAVE_SSE],[Define to 1 to support Streaming SIMD Extensions])
  AH_TEMPLATE([HAVE_SSE2],[Define to 1 to support Streaming SIMD Extensions])
  AH_TEMPLATE([HAVE_SSE3],[Define to 1 to support Streaming SIMD Extensions 3])
  AH_TEMPLATE([HAVE_SSSE3],[Define to 1 to support Supplemental Streaming SIMD Extensions 3])
  AH_TEMPLATE([HAVE_SSE4_1],[Define to 1 to support Streaming SIMD Extensions 4.1])
  AH_TEMPLATE([HAVE_SSE4_2],[Define to 1 to support Streaming SIMD Extensions 4.2])
  AH_TEMPLATE([HAVE_SSE4a],[Define to 1 to support AMD Streaming SIMD Extensions 4a])
  AH_TEMPLATE([HAVE_SHA],[Define to 1 to support Secure Hash Algorithm Extension])
  AH_TEMPLATE([HAVE_AES],[Define to 1 to support Advanced Encryption Standard New Instruction Set (AES-NI)])
  AH_TEMPLATE([HAVE_AVX],[Define to 1 to support Advanced Vector Extensions])
  AH_TEMPLATE([HAVE_FMA3],[Define to 1 to support  Fused Multiply-Add Extensions 3])
  AH_TEMPLATE([HAVE_FMA4],[Define to 1 to support Fused Multiply-Add Extensions 4])
  AH_TEMPLATE([HAVE_XOP],[Define to 1 to support eXtended Operations Extensions])
  AH_TEMPLATE([HAVE_AVX2],[Define to 1 to support Advanced Vector Extensions 2])
  AH_TEMPLATE([HAVE_AVX512_F],[Define to 1 to support AVX-512 Foundation Extensions])
  AH_TEMPLATE([HAVE_AVX512_CD],[Define to 1 to support AVX-512 Conflict Detection Instructions])
  AH_TEMPLATE([HAVE_AVX512_PF],[Define to 1 to support AVX-512 Conflict Prefetch Instructions])
  AH_TEMPLATE([HAVE_AVX512_ER],[Define to 1 to support AVX-512 Exponential & Reciprocal Instructions])
  AH_TEMPLATE([HAVE_AVX512_VL],[Define to 1 to support AVX-512 Vector Length Extensions])
  AH_TEMPLATE([HAVE_AVX512_BW],[Define to 1 to support AVX-512 Byte and Word Instructions])
  AH_TEMPLATE([HAVE_AVX512_DQ],[Define to 1 to support AVX-512 Doubleword and Quadword Instructions])
  AH_TEMPLATE([HAVE_AVX512_IFMA],[Define to 1 to support AVX-512 Integer Fused Multiply Add Instructions])
  AH_TEMPLATE([HAVE_AVX512_VBMI],[Define to 1 to support AVX-512 Vector Byte Manipulation Instructions])
  AH_TEMPLATE([HAVE_NEON],[Define to 1 to support ARM64 NEON Instructions])
  AC_SUBST(SIMD_FLAGS)
  AC_SUBST(SIMD_FLAGS_SSE2)
  AC_SUBST(SIMD_FLAGS_AVX2)
  AC_SUBST(SIMD_FLAGS_AVX512BW)
  AC_SUBST(SIMD_FLAGS_NEON)
  AC_SUBST(CPUEXT_FLAGS)
])
