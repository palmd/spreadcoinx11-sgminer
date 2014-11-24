/*-
 * Copyright 2009 Colin Percival, 2011 ArtForz
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * This file was originally written by Colin Percival as part of the Tarsnap
 * online backup system.
 */

#include "config.h"
#include "miner.h"

#include <stdlib.h>
#include <stdint.h>
#include <string.h>


#include "sph/sph_blake.h"
#include "sph/sph_bmw.h"
#include "sph/sph_groestl.h"
#include "sph/sph_jh.h"
#include "sph/sph_keccak.h"
#include "sph/sph_skein.h"
#include "sph/sph_luffa.h"
#include "sph/sph_cubehash.h"
#include "sph/sph_shavite.h"
#include "sph/sph_simd.h"
#include "sph/sph_echo.h"
#include "sha2.h"

/* Move init out of loop, so init once externally, and then use one single memcpy with that bigger memory block */
typedef struct {
    sph_blake512_context    blake1;
    sph_bmw512_context      bmw1;
    sph_groestl512_context  groestl1;
    sph_skein512_context    skein1;
    sph_jh512_context       jh1;
    sph_keccak512_context   keccak1;
    sph_luffa512_context    luffa1;
    sph_cubehash512_context cubehash1;
    sph_shavite512_context  shavite1;
    sph_simd512_context     simd1;
    sph_echo512_context     echo1;
} Xhash_context_holder;

Xhash_context_holder base_contexts;


void init_Xhash_contexts()
{
    sph_blake512_init(&base_contexts.blake1);
    sph_bmw512_init(&base_contexts.bmw1);
    sph_groestl512_init(&base_contexts.groestl1);
    sph_skein512_init(&base_contexts.skein1);
    sph_jh512_init(&base_contexts.jh1);
    sph_keccak512_init(&base_contexts.keccak1);
    sph_luffa512_init(&base_contexts.luffa1);
    sph_cubehash512_init(&base_contexts.cubehash1);
    sph_shavite512_init(&base_contexts.shavite1);
    sph_simd512_init(&base_contexts.simd1);
    sph_echo512_init(&base_contexts.echo1);
}

/*
 * Encode a length len/4 vector of (uint32_t) into a length len vector of
 * (unsigned char) in big-endian form.  Assumes len is a multiple of 4.
 */
static inline void
be32enc_vect(uint32_t *dst, const uint32_t *src, uint32_t len)
{
	uint32_t i;

	for (i = 0; i < len; i++)
		dst[i] = htobe32(src[i]);
}


void xhash(void *state, const void *input)
{
    init_Xhash_contexts();

    Xhash_context_holder ctx;

    uint32_t hashA[16], hashB[16];
    //blake-bmw-groestl-sken-jh-meccak-luffa-cubehash-shivite-simd-echo
    memcpy(&ctx, &base_contexts, sizeof(base_contexts));

    sph_blake512 (&ctx.blake1, input, 185);
    sph_blake512_close (&ctx.blake1, hashA);

    sph_bmw512 (&ctx.bmw1, hashA, 64);
    sph_bmw512_close(&ctx.bmw1, hashB);

    sph_groestl512 (&ctx.groestl1, hashB, 64);
    sph_groestl512_close(&ctx.groestl1, hashA);

    sph_skein512 (&ctx.skein1, hashA, 64);
    sph_skein512_close(&ctx.skein1, hashB);

    sph_jh512 (&ctx.jh1, hashB, 64);
    sph_jh512_close(&ctx.jh1, hashA);

    sph_keccak512 (&ctx.keccak1, hashA, 64);
    sph_keccak512_close(&ctx.keccak1, hashB);

    sph_luffa512 (&ctx.luffa1, hashB, 64);
    sph_luffa512_close (&ctx.luffa1, hashA);

    sph_cubehash512 (&ctx.cubehash1, hashA, 64);
    sph_cubehash512_close(&ctx.cubehash1, hashB);

    sph_shavite512 (&ctx.shavite1, hashB, 64);
    sph_shavite512_close(&ctx.shavite1, hashA);

    sph_simd512 (&ctx.simd1, hashA, 64);
    sph_simd512_close(&ctx.simd1, hashB);

    sph_echo512 (&ctx.echo1, hashB, 64);
    sph_echo512_close(&ctx.echo1, hashA);

    memcpy(state, hashA, 32);
}

#include "kernel/opencl_rawsha256.cl"

uint32_t k[] = {
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U,
    0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
    0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
    0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
    0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU,
    0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
    0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
    0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
    0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
    0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U,
    0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U,
    0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
    0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
    0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U
};

#include "stdio.h"

void print_data(FILE* pFile, uint8_t* p, int size)
{
    for (int i = 0; i < size; i++)
    {
        if (i % 32 == 0)
            fprintf(pFile, "\n");
        if (i % 4 == 0)
            fprintf(pFile, " ");
        fprintf(pFile, "%c%c", "0123456789abcdef"[p[i] / 16], "0123456789abcdef"[p[i] % 16]);
    }
}

void print_all(uint32_t nonce, uint8_t* block, uint8_t* hash)
{
    char name[16];
    sprintf(name, "z%i.txt", nonce);
    FILE* pFile = fopen(name, "wb");
    print_data(pFile, hash, 32);
    fprintf(pFile, "\n");
    print_data(pFile, block, 200000);
    fclose(pFile);
}

static const uint32_t disorder[8] = {801750719, 1076732275, 1354194884, 1162945305, 1, 0, 0, 0};

static void mul256(uint32_t c[16], const uint32_t a[8], const uint32_t b[8])
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

static void reduce(uint32_t r[16], uint32_t a[16])
{
    for (int i = 0; i < 8; i++)
        r[i] = a[i];
    for (int i = 8; i < 16; i++)
        r[i] = 0;
    mul256(r, a + 8, disorder);
}

static void reverse(uint8_t* p)
{
    for (int i = 0; i < 16; i++)
    {
        uint8_t t = p[i];
        p[i] = p[31-i];
        p[31-i] = t;
    }
}

void darkcoin_regenhash(struct work *work)
{
    const uint32_t* pi32 = (const uint32_t*)&work->data.pok_header;
    uint32_t* pi322 = malloc(4*50000);

    for (int i = 0; i < 200000/4; i++)
        pi322[i] = bswap_32(pi32[i]);

    uint32_t Hash0[8];
    uint32_t Hash[8];
    uint32_t Akinv[8];
    uint32_t bufferA[16];
    uint32_t bufferB[16];

    uint32_t high_nonce = work->data.header.nNonce & ~0x3FUL;

    sha256_ctx ctx;
    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t*)&work->data.header, 84);
    sha256_update(&ctx, (const uint8_t*)&high_nonce, 4);
    sha256_final(&ctx, (uint8_t*)Hash0);

    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t*)Hash0, 32);
    sha256_final(&ctx, (uint8_t*)Hash);

    memcpy(bufferA, work->data.prk, 32);
    memset(bufferA + 8, 0, 32);
    reverse((uint8_t*)Hash);
    mul256(bufferA, (const uint32_t*)work->data.kinv, Hash);
    reduce(bufferB, bufferA);
    reduce(bufferA, bufferB);
    reduce(bufferB, bufferA);
    reverse((uint8_t*)bufferB);

    memcpy(&work->data.header.MinerSignature[33], bufferB, 32);

    ((struct CPokHeader*)pi322)->nNonce = work->data.header.nNonce & ~0x3FUL;
    memcpy(((struct CPokHeader*)pi322)->MinerSignature, work->data.header.MinerSignature, 65);

    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t*)pi322, 200000);
    sha256_update(&ctx, (const uint8_t*)pi322, 200000);
    sha256_final(&ctx, work->data.header.hashWholeBlock);

    xhash(work->hash, &work->data.header);
}
