/*
 * object_dumper.c - Ruby to JSON object conversion
 *
 * Converts Ruby objects to yyjson mutable values for JSON generation.
 */

#include "common.h"
#include "object_dumper.h"
#include <ruby/encoding.h>
#include <math.h>

/* Maximum nesting depth to prevent stack overflow */
#define MAX_NESTING_DEPTH 100

/*
 * Context for tracking circular references and nesting depth
 */
typedef struct {
    yyjson_mut_doc *doc;
    const yyjson_dump_options *opts;
    int depth;
    VALUE visited;  /* Hash for circular reference detection */
} dump_context;

/*
 * Forward declaration
 */
static yyjson_mut_val *dump_ruby_object(VALUE obj, dump_context *ctx);

/*
 * Check for circular references
 */
static void
check_circular_reference(VALUE obj, dump_context *ctx)
{
    if (ctx->depth > MAX_NESTING_DEPTH) {
        rb_raise(eGenerateError, "nesting of %d is too deep", ctx->depth);
    }

    /* Only check for collections (Array, Hash) */
    if (TYPE(obj) != T_ARRAY && TYPE(obj) != T_HASH) {
        return;
    }

    /* Check if we've seen this object before */
    VALUE obj_id = rb_obj_id(obj);
    if (rb_hash_lookup(ctx->visited, obj_id) != Qnil) {
        rb_raise(eGenerateError, "circular reference detected");
    }

    /* Mark as visited */
    rb_hash_aset(ctx->visited, obj_id, Qtrue);
}

/*
 * Unmark object as visited (for backtracking)
 */
static void
unmark_visited(VALUE obj, dump_context *ctx)
{
    if (TYPE(obj) != T_ARRAY && TYPE(obj) != T_HASH) {
        return;
    }

    VALUE obj_id = rb_obj_id(obj);
    rb_hash_delete(ctx->visited, obj_id);
}

/*
 * Dump Ruby String to JSON string
 */
static yyjson_mut_val *
dump_string(VALUE str, dump_context *ctx)
{
    /* Ensure string is UTF-8 */
    str = rb_str_export_to_enc(str, rb_utf8_encoding());

    const char *cstr = RSTRING_PTR(str);
    size_t len = RSTRING_LEN(str);

    return yyjson_mut_strncpy(ctx->doc, cstr, len);
}

/*
 * Dump Ruby Symbol to JSON string
 */
static yyjson_mut_val *
dump_symbol(VALUE sym, dump_context *ctx)
{
    const char *cstr = rb_id2name(SYM2ID(sym));
    return yyjson_mut_str(ctx->doc, cstr);
}

/*
 * Dump Ruby Integer to JSON number
 */
static yyjson_mut_val *
dump_integer(VALUE num, dump_context *ctx)
{
    if (FIXNUM_P(num)) {
        long val = FIX2LONG(num);
        return yyjson_mut_sint(ctx->doc, val);
    } else {
        /* Bignum - convert to int64 if possible */
        long long val = NUM2LL(num);
        return yyjson_mut_sint(ctx->doc, val);
    }
}

/*
 * Dump Ruby Float to JSON number
 */
static yyjson_mut_val *
dump_float(VALUE num, dump_context *ctx)
{
    double val = NUM2DBL(num);

    /* Check for special values */
    if (isinf(val) || isnan(val)) {
        if (!ctx->opts->allow_nan) {
            rb_raise(eGenerateError, "NaN and Infinity not allowed in JSON");
        }
    }

    return yyjson_mut_real(ctx->doc, val);
}

/*
 * Dump Ruby Array to JSON array
 */
static yyjson_mut_val *
dump_array(VALUE ary, dump_context *ctx)
{
    check_circular_reference(ary, ctx);
    ctx->depth++;

    yyjson_mut_val *arr = yyjson_mut_arr(ctx->doc);
    long len = RARRAY_LEN(ary);

    for (long i = 0; i < len; i++) {
        VALUE item = rb_ary_entry(ary, i);
        yyjson_mut_val *json_val = dump_ruby_object(item, ctx);
        yyjson_mut_arr_append(arr, json_val);
    }

    ctx->depth--;
    unmark_visited(ary, ctx);

    return arr;
}

/*
 * Dump Ruby Hash to JSON object
 */
static int
dump_hash_iter(VALUE key, VALUE val, VALUE arg)
{
    dump_context *ctx = (dump_context *)arg;

    /* Convert key to string */
    VALUE key_str;
    if (TYPE(key) == T_STRING) {
        key_str = key;
    } else if (TYPE(key) == T_SYMBOL) {
        key_str = rb_sym2str(key);
    } else {
        key_str = rb_funcall(key, rb_intern("to_s"), 0);
    }

    /* Get the JSON object from context (stored temporarily in opts) */
    yyjson_mut_val *obj = (yyjson_mut_val *)ctx->opts->temp_obj;

    /* Dump the value */
    yyjson_mut_val *json_val = dump_ruby_object(val, ctx);

    /* Add to object */
    key_str = rb_str_export_to_enc(key_str, rb_utf8_encoding());
    const char *key_cstr = RSTRING_PTR(key_str);
    size_t key_len = RSTRING_LEN(key_str);

    yyjson_mut_obj_add(obj, yyjson_mut_strncpy(ctx->doc, key_cstr, key_len), json_val);

    return ST_CONTINUE;
}

static yyjson_mut_val *
dump_hash(VALUE hash, dump_context *ctx)
{
    check_circular_reference(hash, ctx);
    ctx->depth++;

    yyjson_mut_val *obj = yyjson_mut_obj(ctx->doc);

    /* Temporarily store object in context for iterator */
    void *saved_temp = (void *)ctx->opts->temp_obj;
    ((yyjson_dump_options *)ctx->opts)->temp_obj = obj;

    /* Iterate hash */
    rb_hash_foreach(hash, dump_hash_iter, (VALUE)ctx);

    /* Restore temp */
    ((yyjson_dump_options *)ctx->opts)->temp_obj = saved_temp;

    ctx->depth--;
    unmark_visited(hash, ctx);

    return obj;
}

/*
 * Fast path: Check if object is a basic Ruby type that doesn't need as_json()
 *
 * This optimization avoids calling as_json() on Hash, Array, String, Numeric
 * which already have their as_json() method return self.
 */
static bool
is_basic_json_type(VALUE obj)
{
    int type = TYPE(obj);
    return (type == T_NIL || type == T_TRUE || type == T_FALSE ||
            type == T_FIXNUM || type == T_BIGNUM || type == T_FLOAT ||
            type == T_STRING || type == T_SYMBOL ||
            type == T_ARRAY || type == T_HASH);
}

/*
 * Check if object is a Time, Date, or DateTime
 */
static bool
is_time_like(VALUE obj)
{
    return (rb_obj_is_kind_of(obj, rb_cTime) ||
            (rb_const_defined(rb_cObject, rb_intern("Date")) &&
             rb_obj_is_kind_of(obj, rb_const_get(rb_cObject, rb_intern("Date")))) ||
            (rb_const_defined(rb_cObject, rb_intern("DateTime")) &&
             rb_obj_is_kind_of(obj, rb_const_get(rb_cObject, rb_intern("DateTime")))));
}

/*
 * Dump Time/Date/DateTime to ISO8601 string
 */
static yyjson_mut_val *
dump_time(VALUE obj, dump_context *ctx)
{
    /* Call iso8601() or to_s to get ISO8601 formatted string */
    VALUE str;
    if (rb_respond_to(obj, rb_intern("iso8601"))) {
        str = rb_funcall(obj, rb_intern("iso8601"), 0);
    } else if (rb_respond_to(obj, rb_intern("xmlschema"))) {
        str = rb_funcall(obj, rb_intern("xmlschema"), 0);
    } else {
        /* Fallback to to_s */
        str = rb_funcall(obj, id_to_s, 0);
    }
    return dump_string(str, ctx);
}

/*
 * Try to call as_json() if available (Rails compatibility)
 */
static VALUE
try_as_json(VALUE obj, dump_context *ctx)
{
    /* Fast path: Skip as_json() for basic JSON types in compat mode */
    if (ctx->opts->mode == MODE_COMPAT && is_basic_json_type(obj)) {
        return Qnil;  /* Indicates: use default handler */
    }

    /* In Rails mode, always try as_json() for custom objects */
    /* But skip it for basic types as an optimization */
    if (ctx->opts->mode == MODE_RAILS && is_basic_json_type(obj)) {
        return Qnil;  /* Use default handler for basic types */
    }

    if (rb_respond_to(obj, id_as_json)) {
        return rb_funcall(obj, id_as_json, 0);
    }
    return Qnil;
}

/*
 * Dump arbitrary Ruby object
 */
static yyjson_mut_val *
dump_ruby_object(VALUE obj, dump_context *ctx)
{
    switch (TYPE(obj)) {
        case T_NIL:
            return yyjson_mut_null(ctx->doc);

        case T_TRUE:
            return yyjson_mut_true(ctx->doc);

        case T_FALSE:
            return yyjson_mut_false(ctx->doc);

        case T_FIXNUM:
        case T_BIGNUM:
            return dump_integer(obj, ctx);

        case T_FLOAT:
            return dump_float(obj, ctx);

        case T_STRING:
            return dump_string(obj, ctx);

        case T_SYMBOL:
            return dump_symbol(obj, ctx);

        case T_ARRAY:
            return dump_array(obj, ctx);

        case T_HASH:
            return dump_hash(obj, ctx);

        default:
            /* Fast path: Handle Time/Date/DateTime objects */
            if (is_time_like(obj)) {
                return dump_time(obj, ctx);
            }

            /* Try as_json() for custom objects */
            VALUE as_json_result = try_as_json(obj, ctx);
            if (!NIL_P(as_json_result)) {
                return dump_ruby_object(as_json_result, ctx);
            }

            /* Fallback: convert to string */
            VALUE str = rb_funcall(obj, id_to_s, 0);
            return dump_string(str, ctx);
    }
}

/*
 * Public API: Dump a Ruby object to a yyjson mutable document
 */
yyjson_mut_val *
yyjson_dump_ruby_object(VALUE obj, yyjson_mut_doc *doc, const yyjson_dump_options *opts)
{
    dump_context ctx;
    ctx.doc = doc;
    ctx.opts = opts;
    ctx.depth = 0;
    ctx.visited = rb_hash_new();

    return dump_ruby_object(obj, &ctx);
}
