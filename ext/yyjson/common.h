#ifndef YYJSON_RUBY_COMMON_H
#define YYJSON_RUBY_COMMON_H

#include <ruby.h>
#include <ruby/encoding.h>
#include <stdbool.h>
#include "yyjson.h"

/* Module and class references */
extern VALUE mYYJson;
extern VALUE cParser;
extern VALUE eYYJsonError;
extern VALUE eParseError;
extern VALUE eGenerateError;

/* Parsing modes (similar to Oj) */
typedef enum {
    MODE_STRICT = 0,  /* Strict JSON only */
    MODE_COMPAT,      /* JSON gem compatibility */
    MODE_RAILS,       /* Rails/ActiveSupport compatibility */
    MODE_OBJECT,      /* Custom object serialization */
    MODE_CUSTOM       /* Fully customizable */
} yyjson_mode_t;

/* Symbol IDs for common operations */
extern ID id_to_json;
extern ID id_as_json;
extern ID id_to_hash;
extern ID id_to_s;
extern ID id_read;
extern ID id_new;
extern ID id_utc;

/* Common string symbols */
extern ID id_symbolize_names;
extern ID id_freeze;
extern ID id_mode;
extern ID id_max_nesting;
extern ID id_allow_nan;
extern ID id_allow_comments;
extern ID id_create_additions;

/* Error handling macros */
#define RAISE_YYJSON_ERROR(msg) rb_raise(eYYJsonError, "%s", (msg))
#define RAISE_PARSE_ERROR(msg) rb_raise(eParseError, "%s", (msg))
#define RAISE_GENERATE_ERROR(msg) rb_raise(eGenerateError, "%s", (msg))

/* Memory allocation macros using Ruby's allocator */
#define YYJSON_ALLOC(type) ((type *)ruby_xmalloc(sizeof(type)))
#define YYJSON_ALLOC_N(type, n) ((type *)ruby_xcalloc((n), sizeof(type)))
#define YYJSON_REALLOC_N(ptr, type, n) ((type *)ruby_xrealloc((ptr), (n) * sizeof(type)))
#define YYJSON_FREE(ptr) ruby_xfree(ptr)

/* Debug logging (only in debug builds) */
#ifdef DEBUG
#define LOG_DEBUG(fmt, ...) fprintf(stderr, "[yyjson] " fmt "\n", ##__VA_ARGS__)
#else
#define LOG_DEBUG(fmt, ...) ((void)0)
#endif

/* GC-safe string creation */
static inline VALUE
yyjson_safe_str_new(const char *str, size_t len, rb_encoding *enc)
{
    VALUE rb_str;
    if (len == 0) {
        rb_str = rb_str_new("", 0);
    } else {
        rb_str = rb_str_new(str, len);
    }
    rb_enc_associate(rb_str, enc);
    return rb_str_freeze(rb_str); /* Freeze for memory sharing */
}

/* Utility: check if VALUE is nil or false */
static inline bool
yyjson_is_falsey(VALUE val)
{
    return NIL_P(val) || val == Qfalse;
}

#endif /* YYJSON_RUBY_COMMON_H */
