/*
 * X11 kernel implementation.
 *
 * ==========================(LICENSE BEGIN)============================
 *
 * Copyright (c) 2014  phm
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ===========================(LICENSE END)=============================
 *
 * @author   phm <phm@inbox.com>
 */

#ifndef __OPENCL_VERSION__
#include "OpenCLKernel.hpp"
#endif

#ifndef DARKCOIN_CL
#define DARKCOIN_CL

#if __ENDIAN_LITTLE__
#define SPH_LITTLE_ENDIAN 1
#else
#define SPH_BIG_ENDIAN 1
#endif

#define SPH_UPTR sph_u64

typedef unsigned int sph_u32;
typedef int sph_s32;
#ifndef __OPENCL_VERSION__
typedef unsigned long long sph_u64;
typedef long long sph_s64;
#else
typedef unsigned long sph_u64;
typedef long sph_s64;
#endif

#define SPH_64 1
#define SPH_64_TRUE 1

#define SPH_C32(x)    ((sph_u32)(x ## U))
#define SPH_T32(x)    ((x) & SPH_C32(0xFFFFFFFF))
#define SPH_ROTL32(x, n)   SPH_T32(((x) << (n)) | ((x) >> (32 - (n))))
#define SPH_ROTR32(x, n)   SPH_ROTL32(x, (32 - (n)))

#define SPH_C64(x)    ((sph_u64)(x ## UL))
#define SPH_T64(x)    ((x) & SPH_C64(0xFFFFFFFFFFFFFFFF))
#define SPH_ROTL64(x, n)   SPH_T64(((x) << (n)) | ((x) >> (64 - (n))))
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

#include "blake.cl"
#include "bmw.cl"
#include "groestl.cl"
#include "jh.cl"
#include "keccak.cl"
#include "skein.cl"
#include "luffa.cl"
#include "cubehash.cl"
#include "shavite.cl"
#include "simd.cl"
#include "echo.cl"

#define _OPENCL_COMPILER
#include "opencl_rawsha256.cl"

#define SWAP4(x) as_uint(as_uchar4(x).wzyx)
#define SWAP8(x) as_ulong(as_uchar8(x).s76543210)

#if SPH_BIG_ENDIAN
    #define DEC64E(x) (x)
    #define DEC64BE(x) (*(const __global sph_u64 *) (x))
    #define DEC64LE(x) SWAP8(*(const __global sph_u64 *) (x))
    #define DEC64LEng(x) SWAP8(*(const  sph_u64 *) (x))
#else
    #define DEC64E(x) SWAP8(x)
    #define DEC64BE(x) SWAP8(*(const __global sph_u64 *) (x))
    #define DEC64LE(x) (*(const __global sph_u64 *) (x))
    #define DEC64LEng(x) (*(const  sph_u64 *) (x))
#endif


void mul256(uint32_t c[16], __global const uint32_t *a, const uint32_t b[8])
{
    uint64_t r = 0;
    uint8_t carry = 0;
    for (int i = 0; i < 8; i++)
    {
        r += c[i];
        for (int j = 0; j < i + 1; j++)
        {
            uint64_t rold = r;
            r += ((uint64_t)a[j])*b[i - j];
            carry += rold > r;
        }
        c[i] = (uint32_t)(r & 0xFFFFFFFF);
        r = (((uint64_t)carry) << 32) + (r >> 32);
        carry = 0;
    }
    for (int i = 8; i < 15; i++)
    {
        r += c[i];
        for (int j = i - 7; j < 8; j++)
        {
            uint64_t rold = r;
            r += ((uint64_t)a[j])*b[i - j];
            carry += rold > r;
        }
        c[i] = (uint32_t)(r & 0xFFFFFFFF);
        r = (((uint64_t)carry) << 32) + (r >> 32);
        carry = 0;
    }
    c[15] += r;
}

void mul256ng(uint32_t c[16], const uint32_t a[8], const uint32_t b[8])
{
    uint64_t r = 0;
    uint8_t carry = 0;
    for (int i = 0; i < 8; i++)
    {
        r += c[i];
        for (int j = 0; j < i + 1; j++)
        {
            uint64_t rold = r;
            r += ((uint64_t)a[j])*b[i - j];
            carry += rold > r;
        }
        c[i] = (uint32_t)(r & 0xFFFFFFFF);
        r = (((uint64_t)carry) << 32) + (r >> 32);
        carry = 0;
    }
    for (int i = 8; i < 15; i++)
    {
        r += c[i];
        for (int j = i - 7; j < 8; j++)
        {
            uint64_t rold = r;
            r += ((uint64_t)a[j])*b[i - j];
            carry += rold > r;
        }
        c[i] = (uint32_t)(r & 0xFFFFFFFF);
        r = (((uint64_t)carry) << 32) + (r >> 32);
        carry = 0;
    }
    c[15] += r;
}
void reduce(uint32_t r[16], const uint32_t a[16])
{
    const uint32_t disorder[8] = {801750719, 1076732275, 1354194884, 1162945305, 1, 0, 0, 0};
    for (int i = 0; i < 8; i++)
        r[i] = a[i];
    for (int i = 8; i < 16; i++)
        r[i] = 0;
    mul256ng(r, a + 8, disorder);
}

void reverse2(uint8_t* p)
{
    for (int i = 0; i < 16; i++)
    {
        uint8_t t = p[i];
        p[i] = p[31-i];
        p[31-i] = t;
    }
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void signature(__global const unsigned char* block2, __global uint64_t *hashWholeBlock_big, __global uint64_t *signbe_big)
{

    uint32_t full_nonce = get_global_id(0);
    uint32_t high_nonce = full_nonce * 64;// & ~((uint32_t)0x3F);
    //uint32_t low_nonce = full_nonce & 0x3F;

	__global const unsigned char* block = block2 + 64;
    __global const unsigned char* kinv = block2;
    __global const unsigned char* prk = block2 + 32;

    __global uint64_t *hashWholeBlock = hashWholeBlock_big + (4*(high_nonce/64));
    __global uint64_t *signbe = signbe_big + (5*(high_nonce/64));

    //if ((high_nonce & 0x3F) == 0)
    {

    const uint32_t disorder[8] = {801750719, 1076732275, 1354194884, 1162945305, 1, 0, 0, 0};

    uint32_t hh2[8] = {SH0, SH1, SH2, SH3, SH4, SH5, SH6, SH7};
    uint32_t bufferB[16];
    uint32_t bufferA[16];
    {
        uint32_t hh[8] = {SH0, SH1, SH2, SH3, SH4, SH5, SH6, SH7};
        {
        uint32_t a = SH0;
        uint32_t b = SH1;
        uint32_t c = SH2;
        uint32_t d = SH3;
        uint32_t e = SH4;
        uint32_t f = SH5;
        uint32_t g = SH6;
        uint32_t h = SH7;
        uint32_t t;


        {
            int i = 0;
            a = hh[0];
            b = hh[1];
            c = hh[2];
            d = hh[3];
            e = hh[4];
            f = hh[5];
            g = hh[6];
            h = hh[7];
            uint32_t w[16];
            #pragma unroll
            for (int j = 0; j < 16; j++)
                w[j] = SWAP4(((__global uint32_t*)block)[i*16 + j]);
            SHA256()
            hh[0] += a;
            hh[1] += b;
            hh[2] += c;
            hh[3] += d;
            hh[4] += e;
            hh[5] += f;
            hh[6] += g;
            hh[7] += h;
        }

        {
            int i = 1;
            a = hh[0];
            b = hh[1];
            c = hh[2];
            d = hh[3];
            e = hh[4];
            f = hh[5];
            g = hh[6];
            h = hh[7];
            uint32_t w[16];
            #pragma unroll
            for (int j = 0; j < 5; j++)
                w[j] = SWAP4(((__global uint32_t*)block)[i*16 + j]);
            w[5] = SWAP4(high_nonce);
            w[6] = 0x80000000;
            for (int j = 7; j < 15; j++)
                w[j] = 0;
            w[15] = 704;
            SHA256()
            hh[0] += a;
            hh[1] += b;
            hh[2] += c;
            hh[3] += d;
            hh[4] += e;
            hh[5] += f;
            hh[6] += g;
            hh[7] += h;
        }
        }
        {
                    uint32_t a = SH0;
        uint32_t b = SH1;
        uint32_t c = SH2;
        uint32_t d = SH3;
        uint32_t e = SH4;
        uint32_t f = SH5;
        uint32_t g = SH6;
        uint32_t h = SH7;
        uint32_t t;

        {
            a = hh2[0];
            b = hh2[1];
            c = hh2[2];
            d = hh2[3];
            e = hh2[4];
            f = hh2[5];
            g = hh2[6];
            h = hh2[7];
            uint32_t w[16];
            #pragma unroll
            for (int j = 0; j < 8; j++)
                w[j] = hh[j];
            w[8] = 0x80000000;
            for (int j = 9; j < 15; j++)
                w[j] = 0;
            w[15] = 32*8;
            SHA256()
            hh2[0] += a;
            hh2[1] += b;
            hh2[2] += c;
            hh2[3] += d;
            hh2[4] += e;
            hh2[5] += f;
            hh2[6] += g;
            hh2[7] += h;
        }
        }

        for (int i = 0; i < 8; i++)
            bufferA[i] = ((__global const uint32_t*)prk)[i];
        for (int i = 8; i < 16; i++)
            bufferA[i] = 0;

        for (int i = 0; i < 8; i++)
            hh2[i] = SWAP4(hh2[i]);
        reverse2((uint8_t*)hh2);
        mul256(bufferA, (__global const uint32_t*)kinv, hh2);
        reduce(bufferB, bufferA);
        reduce(bufferA, bufferB);
        reduce(bufferB, bufferA);
        reverse2((uint8_t*)(bufferB));
    }

    uint8_t* ps = (uint8_t*)bufferB;
    uint8_t psign[33];
    psign[0] = block[152];
    for (int i = 0; i < 32; i++)
        psign[i + 1] = ps[i];

    uint64_t signature8[5];
    signature8[0] = psign[0];
    signature8[1] = psign[8];
    signature8[2] = psign[16];
    signature8[3] = psign[24];
    signature8[4] = psign[32];

    uint64_t signature[4];
    signature[0] = (DEC64LEng(psign +  0) >> 8) | (signature8[1] << 56);
    signature[1] = (DEC64LEng(psign +  8) >> 8) | (signature8[2] << 56);
    signature[2] = (DEC64LEng(psign + 16) >> 8) | (signature8[3] << 56);
    signature[3] = (DEC64LEng(psign + 24) >> 8) | (signature8[4] << 56);

    signature8[1] = signature[0] >> 56;
    signature8[2] = signature[1] >> 56;
    signature8[3] = signature[2] >> 56;
    signature8[4] = signature[3] >> 56;

    signbe[0] = SWAP8((signature[0] << 8) | signature8[0]);
    signbe[1] = SWAP8((signature[1] << 8) | signature8[1]);
    signbe[2] = SWAP8((signature[2] << 8) | signature8[2]);
    signbe[3] = SWAP8((signature[3] << 8) | signature8[3]);
    signbe[4] = (signature8[4] << 56) | 0x80000000000000;

    uint32_t a = SH0;
    uint32_t b = SH1;
    uint32_t c = SH2;
    uint32_t d = SH3;
    uint32_t e = SH4;
    uint32_t f = SH5;
    uint32_t g = SH6;
    uint32_t h = SH7;
    uint32_t t;

    uint32_t hh[8] = {SH0, SH1, SH2, SH3, SH4, SH5, SH6, SH7};

    __global const uint32_t* pPokData = (__global const uint32_t*)(block + 192);

    uint32_t sig32[10];
    for (int i = 0; i < 5; i++)
    {
        uint64_t sws = signbe[i];
        sig32[2*i] = (uint32_t)(sws >> 32);
        sig32[2*i + 1] = (uint32_t)(sws & 0xFFFFFFFF);
    }
    sig32[8] = (sig32[8] & 0xFF000000) | 0x00020000; // (SWAP4(*(__global const uint32_t*)block) >> 8);

    for (int N = 0; N < 2; N++)
    {
        {
            a = hh[0];
            b = hh[1];
            c = hh[2];
            d = hh[3];
            e = hh[4];
            f = hh[5];
            g = hh[6];
            h = hh[7];
            uint32_t w[16];
            w[0] = SWAP4(high_nonce);
            for (int j = 1; j < 11; j++)
                w[j] = pPokData[j];
            for (int j = 11; j < 16; j++)
                w[j] = sig32[j - 11];
            SHA256()
            hh[0] += a;
            hh[1] += b;
            hh[2] += c;
            hh[3] += d;
            hh[4] += e;
            hh[5] += f;
            hh[6] += g;
            hh[7] += h;
        }

        {
            int i = 1;
            a = hh[0];
            b = hh[1];
            c = hh[2];
            d = hh[3];
            e = hh[4];
            f = hh[5];
            g = hh[6];
            h = hh[7];
            uint32_t w[16];
            for (int j = 0; j < 4; j++)
                w[j] = sig32[j + 5];
            #pragma unroll
            for (int j = 4; j < 16; j++)
                w[j] = pPokData[i*16 + j];
            SHA256()
            hh[0] += a;
            hh[1] += b;
            hh[2] += c;
            hh[3] += d;
            hh[4] += e;
            hh[5] += f;
            hh[6] += g;
            hh[7] += h;
        }

        for (int i = 2; i < 3125; i++)
        {
            a = hh[0];
            b = hh[1];
            c = hh[2];
            d = hh[3];
            e = hh[4];
            f = hh[5];
            g = hh[6];
            h = hh[7];
            uint32_t w[16];
            #pragma unroll
            for (int j = 0; j < 16; j++)
                w[j] = pPokData[i*16 + j];
            SHA256()
            hh[0] += a;
            hh[1] += b;
            hh[2] += c;
            hh[3] += d;
            hh[4] += e;
            hh[5] += f;
            hh[6] += g;
            hh[7] += h;
        }
    }

    {
        int i = 3125;
        a = hh[0];
        b = hh[1];
        c = hh[2];
        d = hh[3];
        e = hh[4];
        f = hh[5];
        g = hh[6];
        h = hh[7];
        uint32_t w[16];
        #pragma unroll
        for (int j = 0; j < 16; j++)
            w[j] = pPokData[i*16 + j];
        SHA256()
        hh[0] += a;
        hh[1] += b;
        hh[2] += c;
        hh[3] += d;
        hh[4] += e;
        hh[5] += f;
        hh[6] += g;
        hh[7] += h;
    }

    hashWholeBlock[0] = (((uint64_t)hh[0]) << 32) | hh[1];
    hashWholeBlock[1] = (((uint64_t)hh[2]) << 32) | hh[3];
    hashWholeBlock[2] = (((uint64_t)hh[4]) << 32) | hh[5];
    hashWholeBlock[3] = (((uint64_t)hh[6]) << 32) | hh[7];

    } // first block
    barrier(CLK_LOCAL_MEM_FENCE);
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void spreadBlake(__global const unsigned char* block2, __global uint64_t *hashWholeBlock_big, __global uint64_t *signbe_big, volatile __global hash_t* hashes) {

    uint32_t full_nonce = get_global_id(0);
    uint32_t high_nonce = full_nonce & ~((uint32_t)0x3F);
    uint32_t low_nonce = full_nonce & 0x3F;
    __global hash_t *hash = &(hashes[full_nonce-get_global_offset(0)]);

    __global uint64_t *hashWholeBlock = hashWholeBlock_big + (4*(high_nonce/64));
    __global uint64_t *signbe = signbe_big + (5*(high_nonce/64));

    __global const unsigned char* block = block2 + 64;

    uint32_t nonce = high_nonce + low_nonce;

    // blake
{
    sph_u64 H0 = SPH_C64(0x6A09E667F3BCC908), H1 = SPH_C64(0xBB67AE8584CAA73B);
    sph_u64 H2 = SPH_C64(0x3C6EF372FE94F82B), H3 = SPH_C64(0xA54FF53A5F1D36F1);
    sph_u64 H4 = SPH_C64(0x510E527FADE682D1), H5 = SPH_C64(0x9B05688C2B3E6C1F);
    sph_u64 H6 = SPH_C64(0x1F83D9ABFB41BD6B), H7 = SPH_C64(0x5BE0CD19137E2179);
    sph_u64 S0 = 0, S1 = 0, S2 = 0, S3 = 0;
    sph_u64 T0 = SPH_C64(0xFFFFFFFFFFFFFC00) + (80 << 3), T1 = 0xFFFFFFFFFFFFFFFF;;

    T0 = 1024;
    T1 = 0;

/*    if ((T0 = SPH_T64(T0 + 1024)) < 1024)
    {
        T1 = SPH_T64(T1 + 1);
    }*/
    sph_u64 M0, M1, M2, M3, M4, M5, M6, M7;
    sph_u64 M8, M9, MA, MB, MC, MD, ME, MF;
    sph_u64 V0, V1, V2, V3, V4, V5, V6, V7;
    sph_u64 V8, V9, VA, VB, VC, VD, VE, VF;
    M0 = DEC64BE(block +   0);
    M1 = DEC64BE(block +   8);
    M2 = DEC64BE(block +  16);
    M3 = DEC64BE(block +  24);
    M4 = DEC64BE(block +  32);
    M5 = DEC64BE(block +  40);
    M6 = DEC64BE(block +  48);
    M7 = DEC64BE(block +  56);
    M8 = DEC64BE(block +  64);
    M9 = DEC64BE(block +  72);
    MA = DEC64BE(block +  80);
    MA &= 0xFFFFFFFF00000000;
    MA ^= SWAP4(nonce);
    MB = hashWholeBlock[0];
    MC = hashWholeBlock[1];
    MD = hashWholeBlock[2];
    ME = hashWholeBlock[3];
    MF = DEC64BE(block + 120);

    COMPRESS64;

    T0 = 1480;
    T1 = 0;

    M0 = DEC64BE(block + 128);
    M1 = DEC64BE(block + 136);
    M2 = DEC64BE(block + 144);
    M3 = signbe[0];
    M4 = signbe[1];
    M5 = signbe[2];
    M6 = signbe[3];
    M7 = signbe[4];//(((sph_u64)block[184]) << 56) | 0x80000000000000;
    M8 = 0;
    M9 = 0;
    MA = 0;
    MB = 0;
    MC = 0;
    MD = 1;
    ME = 0;
    MF = 1480;

    COMPRESS64;

    hash->h8[0] = H0;
    hash->h8[1] = H1;
    hash->h8[2] = H2;
    hash->h8[3] = H3;
    hash->h8[4] = H4;
    hash->h8[5] = H5;
    hash->h8[6] = H6;
    hash->h8[7] = H7;
}
barrier(CLK_GLOBAL_MEM_FENCE);
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void spreadSearch(volatile __global hash_t* hashes, volatile __global uint* output, const ulong target)
{
    uint gid = get_global_id(0);
    __global hash_t *hash = &(hashes[gid-get_global_offset(0)]);

    bool result = (hash->h8[3] <= target);
    if (result)
        output[output[0xFF]++] = gid; //SWAP4(gid);
    barrier(CLK_GLOBAL_MEM_FENCE);
}

#endif // DARKCOIN_CL
