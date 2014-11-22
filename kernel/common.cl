/*
 * common.cl
 *
 *  Created on: 10/06/2014
 *      Author: girino
 */

#ifndef COMMON_CL_
#define COMMON_CL_

#ifdef __ECLIPSE_EDITOR__
#include "OpenCLKernel.hpp"
#endif

#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable

#define SPH_LITTLE_ENDIAN 1

#if __ENDIAN_LITTLE__
#define SPH_LITTLE_ENDIAN 1
#else
//#define SPH_BIG_ENDIAN 1
#error big endian not supported
#endif

#define SPH_UPTR sph_u64

typedef unsigned int sph_u32;
typedef int sph_s32;
typedef unsigned long sph_u64;
typedef long sph_s64;

#define SPH_64 1
#define SPH_64_TRUE 1

#define SPH_C32(x)    ((sph_u32)(x ## U))
#define SPH_T32(x)    ((x) & SPH_C32(0xFFFFFFFF))
//#define SPH_ROTL32(x, n)   SPH_T32(((x) << (n)) | ((x) >> (32 - (n))))
#define SPH_ROTL32(x, n)   SPH_T32(rotate((sph_u32)(x), (sph_u32)(n)))
#define SPH_ROTR32(x, n)   SPH_ROTL32(x, (32 - (n)))

#define SPH_C64(x)    ((sph_u64)(x ## UL))
#define SPH_T64(x)    ((x) & SPH_C64(0xFFFFFFFFFFFFFFFF))
//#define SPH_ROTL64(x, n)   SPH_T64(((x) << (n)) | ((x) >> (64 - (n))))
#define SPH_ROTL64(x, n)   SPH_T64(rotate((sph_u64)(x), (sph_u64)(n)))
#define SPH_ROTR64(x, n)   SPH_ROTL64(x, (64 - (n)))

#define SPH_ECHO_64 1
#define SPH_KECCAK_64 1
#define SPH_JH_64 1
#define SPH_SIMD_NOCOPY 0
#define SPH_KECCAK_NOCOPY 0
#define SPH_COMPACT_BLAKE_64 0
#define SPH_LUFFA_PARALLEL 0
#define SPH_SMALL_FOOTPRINT_GROESTL 0
#define SPH_GROESTL_BIG_ENDIAN 0
#define SPH_CUBEHASH_UNROLL 0
#define SPH_KECCAK_UNROLL   0
#define SPH_HAMSI_EXPAND_BIG 1

#define SWAP4(x) as_uint(as_uchar4(x).wzyx)
#define SWAP8(x) as_ulong(as_uchar8(x).s76543210)

#if SPH_BIG_ENDIAN
    #define DEC64E(x) (x)
    #define DEC64BE(x) (*(const __global sph_u64 *) (x));
#else
    #define DEC64E(x) SWAP8(x)
    #define DEC64BE(x) SWAP8(*(const __global sph_u64 *) (x));
#endif

typedef union {
    unsigned char h1[64];
    uint h4[16];
    ulong h8[8];
} hash_t;


#endif /* COMMON_CL_ */
