/*
    https://code.google.com/p/fast-hash
*/

module util.fasthash;

/**
 * fasthash64 - 64-bit implementation of fasthash
 * @buf:  data buffer
 * @len:  data size
 * @seed: the seed
 */
public ulong fasthash64(const void* buf, const size_t len, const ulong seed) {
    const ulong m = 0x880355f21e6d1965UL;

    ulong* pos = cast(ulong*)buf;
    const ulong* end = pos + (len / 8);
    ulong h = seed ^ (len * m);
    ulong v;

    while (pos != end) {
        v = *pos++;
        h ^= mix(v);
        h *= m;
    }

    switch (len & 7) {
        case 7: v ^= cast(ulong)pos[6] << 48; goto case;
        case 6: v ^= cast(ulong)pos[5] << 40; goto case;
        case 5: v ^= cast(ulong)pos[4] << 32; goto case;
        case 4: v ^= cast(ulong)pos[3] << 24; goto case;
        case 3: v ^= cast(ulong)pos[2] << 16; goto case;
        case 2: v ^= cast(ulong)pos[1] << 8; goto case;
        case 1:
            v ^= cast(ulong)pos[0];
            h ^= mix(v);
            h *= m;
            goto default;
        default:
    }

    return mix(h);
}

/**
 * fasthash32 - 32-bit implementation of fasthash
 * @buf:  data buffer
 * @len:  data size
 * @seed: the seed
 */
public uint fasthash32(const void *buf, const size_t len, const uint seed) {       
    const ulong h = fasthash64(buf, len, seed);
    
    // the following trick converts the 64-bit hashcode to Fermat
    // residue, which shall retain information from both the higher
    // and lower parts of hashcode.
    return cast(uint)(h - (h >> 32));
}

// Compression function for Merkle-Damgard construction.
// This function is generated using the framework provided.
private ulong mix(ulong h) {
    h ^= h >> 23;
    h *= 0x2127599bf4325c37UL;
    h ^= h >> 47;
    
    return h;
}