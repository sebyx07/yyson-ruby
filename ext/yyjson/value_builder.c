/*
 * value_builder.c - JSON to Ruby object conversion (OPTIMIZED v4)
 *
 * Aggressive optimizations inspired by Ruby JSON gem:
 * 1. Separate string/symbol caches to avoid rb_sym2str overhead
 * 2. Direct yyjson value access where safe
 * 3. rb_ary_new_from_values() for single-call array creation
 * 4. rb_hash_bulk_insert() for batch hash insertion
 * 5. Custom fast memcmp using 64-bit comparisons
 * 6. Stack allocation for small collections
 * 7. Hash+length sorted cache for O(log n) lookups
 */

#include "common.h"
#include "value_builder.h"
#include <string.h>
#include <ctype.h>

/* Branch prediction */
#ifndef RB_LIKELY
#define RB_LIKELY(x)   __builtin_expect(!!(x), 1)
#define RB_UNLIKELY(x) __builtin_expect(!!(x), 0)
#endif

/* Force inlining */
#if defined(__GNUC__) || defined(__clang__)
#define YY_INLINE static inline __attribute__((always_inline))
#else
#define YY_INLINE static inline
#endif

/* Little-endian 64-bit detection */
#if defined(__x86_64__) || defined(_M_X64) || defined(__aarch64__)
#define YY_LE64
#endif

/* UTF-8 encoding */
static rb_encoding *utf8_enc = NULL;

/*
 * Pre-cached small integers for faster number conversion
 * Ruby caches FIXNUM internally, but avoiding the macro expansion helps
 */
#define SMALL_INT_MIN -10
#define SMALL_INT_MAX 100
static VALUE small_ints[SMALL_INT_MAX - SMALL_INT_MIN + 1];

YY_INLINE VALUE
fast_int(long n)
{
    if (n >= SMALL_INT_MIN && n <= SMALL_INT_MAX) {
        return small_ints[n - SMALL_INT_MIN];
    }
    return LONG2FIX(n);
}

/*
 * Separate caches for strings and symbols (avoids rb_sym2str overhead)
 */
#define CACHE_SIZE 63
#define CACHE_MAX_LEN 55

typedef struct {
    const char *ptr;   /* Pointer to key string (in yyjson memory) */
    uint32_t len;      /* Key length */
    uint32_t hash;     /* Precomputed hash for faster comparison */
    VALUE val;         /* Cached Ruby string or symbol */
} cache_entry_t;

typedef struct {
    cache_entry_t entries[CACHE_SIZE];
    int len;
} string_cache_t;

/*
 * FNV-1a hash for cache lookup
 */
YY_INLINE uint32_t
fnv1a(const char *s, size_t len)
{
    uint32_t h = 2166136261u;
    for (size_t i = 0; i < len; i++) {
        h ^= (uint8_t)s[i];
        h *= 16777619u;
    }
    return h;
}

/*
 * Fast memcmp for short strings
 */
#ifdef YY_LE64
#if __has_builtin(__builtin_bswap64)
YY_INLINE int
fast_cmp(const char *a, const char *b, size_t len)
{
    size_t i = 0;
    while (i + 8 <= len) {
        uint64_t va, vb;
        memcpy(&va, a + i, 8);
        memcpy(&vb, b + i, 8);
        if (va != vb) {
            va = __builtin_bswap64(va);
            vb = __builtin_bswap64(vb);
            return (va < vb) ? -1 : 1;
        }
        i += 8;
    }
    while (i < len) {
        if (a[i] != b[i]) return (a[i] < b[i]) ? -1 : 1;
        i++;
    }
    return 0;
}
#else
#define fast_cmp memcmp
#endif
#else
#define fast_cmp memcmp
#endif

/*
 * Initialize value builder
 */
void
yyjson_value_builder_init(void)
{
    utf8_enc = rb_utf8_encoding();

    /* Pre-cache small integers */
    for (long i = SMALL_INT_MIN; i <= SMALL_INT_MAX; i++) {
        small_ints[i - SMALL_INT_MIN] = LONG2FIX(i);
    }
}

/*
 * Create UTF-8 string
 */
YY_INLINE VALUE
make_str(const char *s, size_t len)
{
#ifdef HAVE_RB_UTF8_STR_NEW
    return rb_utf8_str_new(s, len);
#else
    return rb_enc_str_new(s, len, utf8_enc);
#endif
}

/*
 * Create frozen interned string
 */
YY_INLINE VALUE
make_fstr(const char *s, size_t len)
{
#ifdef HAVE_RB_ENC_INTERNED_STR
    return rb_enc_interned_str(s, len, utf8_enc);
#else
    VALUE str = rb_enc_str_new(s, len, utf8_enc);
    return rb_str_freeze(str);
#endif
}

/*
 * Binary search in sorted cache (sorted by hash, then length)
 */
YY_INLINE int
cache_search(string_cache_t *c, const char *s, size_t len, uint32_t h)
{
    int lo = 0, hi = c->len - 1;
    while (lo <= hi) {
        int mid = (lo + hi) >> 1;
        cache_entry_t *e = &c->entries[mid];
        if (e->hash < h) {
            lo = mid + 1;
        } else if (e->hash > h) {
            hi = mid - 1;
        } else if (e->len < len) {
            lo = mid + 1;
        } else if (e->len > len) {
            hi = mid - 1;
        } else {
            int cmp = fast_cmp(s, e->ptr, len);
            if (cmp == 0) return mid;
            if (cmp > 0) lo = mid + 1;
            else hi = mid - 1;
        }
    }
    return -(lo + 1);  /* Insertion point */
}

/*
 * Insert into cache at position
 */
YY_INLINE void
cache_insert(string_cache_t *c, int pos, const char *s, size_t len, uint32_t h, VALUE v)
{
    if (c->len >= CACHE_SIZE) return;
    memmove(&c->entries[pos + 1], &c->entries[pos],
            (c->len - pos) * sizeof(cache_entry_t));
    c->entries[pos] = (cache_entry_t){ .ptr = s, .len = (uint32_t)len, .hash = h, .val = v };
    c->len++;
}

/*
 * Get or create cached string key
 */
YY_INLINE VALUE
get_str_key(string_cache_t *c, const char *s, size_t len)
{
    if (RB_UNLIKELY(len > CACHE_MAX_LEN || len == 0 || !isalpha((unsigned char)s[0]))) {
        return make_fstr(s, len);
    }

    uint32_t h = fnv1a(s, len);
    int idx = cache_search(c, s, len, h);

    if (idx >= 0) return c->entries[idx].val;  /* Hit */

    VALUE v = make_fstr(s, len);
    cache_insert(c, -(idx + 1), s, len, h, v);
    return v;
}

/*
 * Get or create cached symbol key
 */
YY_INLINE VALUE
get_sym_key(string_cache_t *c, const char *s, size_t len)
{
    if (RB_UNLIKELY(len > CACHE_MAX_LEN || len == 0 || !isalpha((unsigned char)s[0]))) {
        return ID2SYM(rb_intern2(s, len));
    }

    uint32_t h = fnv1a(s, len);
    int idx = cache_search(c, s, len, h);

    if (idx >= 0) return c->entries[idx].val;  /* Hit */

    VALUE v = ID2SYM(rb_intern2(s, len));
    cache_insert(c, -(idx + 1), s, len, h, v);
    return v;
}

/*
 * Build number from yyjson value
 * Use unsafe_yyjson_get_* for direct access (faster)
 * Use fast_int for small integers (cached lookup)
 */
YY_INLINE VALUE
build_num(yyjson_val *v)
{
    uint8_t tag = unsafe_yyjson_get_tag(v);
    uint8_t sub = tag & YYJSON_SUBTYPE_MASK;

    if (RB_LIKELY(sub == YYJSON_SUBTYPE_SINT)) {
        int64_t n = unsafe_yyjson_get_sint(v);
        /* Fast path for small integers */
        if (RB_LIKELY(n >= SMALL_INT_MIN && n <= SMALL_INT_MAX)) {
            return small_ints[n - SMALL_INT_MIN];
        }
        if (RB_LIKELY(n >= FIXNUM_MIN && n <= FIXNUM_MAX)) {
            return LONG2FIX((long)n);
        }
        return LL2NUM(n);
    }

    if (sub == YYJSON_SUBTYPE_UINT) {
        uint64_t n = unsafe_yyjson_get_uint(v);
        /* Fast path for small integers */
        if (RB_LIKELY(n <= SMALL_INT_MAX)) {
            return small_ints[n - SMALL_INT_MIN];
        }
        if (RB_LIKELY(n <= (uint64_t)FIXNUM_MAX)) {
            return LONG2FIX((long)n);
        }
        return ULL2NUM(n);
    }

    return DBL2NUM(unsafe_yyjson_get_real(v));
}

/* Forward declaration */
typedef struct parse_ctx {
    const yyjson_parse_options *opts;
    string_cache_t *str_cache;
    string_cache_t *sym_cache;
} parse_ctx_t;

static VALUE build_val(yyjson_val *v, parse_ctx_t *ctx);

/*
 * Build array using rb_ary_new_from_values
 */
static VALUE
build_arr(yyjson_val *v, parse_ctx_t *ctx)
{
    size_t len = yyjson_arr_size(v);

    if (RB_UNLIKELY(len == 0)) {
        VALUE arr = rb_ary_new();
        if (ctx->opts->freeze) rb_ary_freeze(arr);
        return arr;
    }

    /* Stack or heap allocation */
    VALUE stack_buf[128];
    VALUE *vals = (len <= 128) ? stack_buf : ALLOC_N(VALUE, len);

    /* Use yyjson iterator for safe traversal */
    yyjson_arr_iter iter;
    yyjson_arr_iter_init(v, &iter);

    size_t i = 0;
    yyjson_val *item;
    while ((item = yyjson_arr_iter_next(&iter))) {
        vals[i++] = build_val(item, ctx);
    }

    VALUE arr = rb_ary_new_from_values(len, vals);

    if (vals != stack_buf) xfree(vals);
    if (ctx->opts->freeze) rb_ary_freeze(arr);

    return arr;
}

/*
 * Build hash using rb_hash_bulk_insert
 */
static VALUE
build_obj(yyjson_val *v, parse_ctx_t *ctx)
{
    size_t len = yyjson_obj_size(v);

    if (RB_UNLIKELY(len == 0)) {
        VALUE hash = rb_hash_new();
        if (ctx->opts->freeze) rb_hash_freeze(hash);
        return hash;
    }

#ifdef HAVE_RB_HASH_NEW_CAPA
    VALUE hash = rb_hash_new_capa(len);
#else
    VALUE hash = rb_hash_new();
#endif

    /* Stack or heap allocation for pairs */
    VALUE stack_buf[256];
    size_t pairs_len = len * 2;
    VALUE *pairs = (pairs_len <= 256) ? stack_buf : ALLOC_N(VALUE, pairs_len);

    bool sym = ctx->opts->symbolize_names;
    string_cache_t *cache = sym ? ctx->sym_cache : ctx->str_cache;

    /* Use yyjson iterator for safe traversal */
    yyjson_obj_iter iter;
    yyjson_obj_iter_init(v, &iter);

    size_t pi = 0;
    yyjson_val *key;
    while ((key = yyjson_obj_iter_next(&iter))) {
        yyjson_val *val = yyjson_obj_iter_get_val(key);

        const char *ks = unsafe_yyjson_get_str(key);
        size_t klen = unsafe_yyjson_get_len(key);
        pairs[pi++] = sym ? get_sym_key(cache, ks, klen) : get_str_key(cache, ks, klen);
        pairs[pi++] = build_val(val, ctx);
    }

#ifdef HAVE_RB_HASH_BULK_INSERT
    rb_hash_bulk_insert(pairs_len, pairs, hash);
#else
    for (size_t i = 0; i < pairs_len; i += 2) {
        rb_hash_aset(hash, pairs[i], pairs[i + 1]);
    }
#endif

    if (pairs != stack_buf) xfree(pairs);
    if (ctx->opts->freeze) rb_hash_freeze(hash);

    return hash;
}

/*
 * Build Ruby value from yyjson value
 */
static VALUE
build_val(yyjson_val *v, parse_ctx_t *ctx)
{
    uint8_t tag = unsafe_yyjson_get_tag(v);
    uint8_t type = tag & YYJSON_TYPE_MASK;

    switch (type) {
        case YYJSON_TYPE_NULL:
            return Qnil;

        case YYJSON_TYPE_BOOL:
            return (tag & YYJSON_SUBTYPE_MASK) ? Qtrue : Qfalse;

        case YYJSON_TYPE_NUM:
            return build_num(v);

        case YYJSON_TYPE_STR: {
            const char *s = unsafe_yyjson_get_str(v);
            size_t len = unsafe_yyjson_get_len(v);
            return ctx->opts->freeze ? make_fstr(s, len) : make_str(s, len);
        }

        case YYJSON_TYPE_ARR:
            return build_arr(v, ctx);

        case YYJSON_TYPE_OBJ:
            return build_obj(v, ctx);

        default:
            return Qnil;
    }
}

/*
 * Build value without cache (for primitives and small docs)
 */
YY_INLINE VALUE
build_val_simple(yyjson_val *v, bool freeze)
{
    uint8_t tag = unsafe_yyjson_get_tag(v);
    uint8_t type = tag & YYJSON_TYPE_MASK;

    switch (type) {
        case YYJSON_TYPE_NULL:
            return Qnil;
        case YYJSON_TYPE_BOOL:
            return (tag & YYJSON_SUBTYPE_MASK) ? Qtrue : Qfalse;
        case YYJSON_TYPE_NUM:
            return build_num(v);
        case YYJSON_TYPE_STR: {
            const char *s = unsafe_yyjson_get_str(v);
            size_t len = unsafe_yyjson_get_len(v);
            return freeze ? make_fstr(s, len) : make_str(s, len);
        }
        default:
            return Qnil;  /* Arrays/objects need full path */
    }
}

/*
 * Public API: Build Ruby object from yyjson document
 */
VALUE
yyjson_build_ruby_object(yyjson_doc *doc, const yyjson_parse_options *opts)
{
    if (RB_UNLIKELY(!doc || !doc->root)) return Qnil;

    yyjson_val *root = doc->root;
    uint8_t type = unsafe_yyjson_get_tag(root) & YYJSON_TYPE_MASK;

    /* Fast path for primitives (no cache needed) */
    if (type < YYJSON_TYPE_ARR) {
        return build_val_simple(root, opts->freeze);
    }

    /* Initialize caches only for containers */
    string_cache_t str_cache = { .len = 0 };
    string_cache_t sym_cache = { .len = 0 };

    parse_ctx_t ctx = {
        .opts = opts,
        .str_cache = &str_cache,
        .sym_cache = &sym_cache
    };

    return build_val(root, &ctx);
}
