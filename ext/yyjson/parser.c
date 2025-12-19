/*
 * parser.c - yyjson document wrapper and parsing functions
 *
 * Handles JSON parsing from strings and files using the yyjson library.
 */

#include "common.h"
#include "value_builder.h"
#include "parser.h"
#include <math.h>

/*
 * Parse JSON from a string
 *
 * @param json_str The JSON string to parse
 * @param opts Parse options
 * @return Ruby object representing the parsed JSON
 */
VALUE
yyjson_parse_string(VALUE json_str, const yyjson_parse_options *opts)
{
    /* Ensure we have a string */
    Check_Type(json_str, T_STRING);

    const char *json = RSTRING_PTR(json_str);
    size_t len = RSTRING_LEN(json_str);

    yyjson_doc *doc;
    yyjson_read_err err;

    /* Fast path: default options (allow_nan + allow_comments) */
    if (opts->allow_nan && opts->allow_comments) {
        static const yyjson_read_flag default_flg =
            YYJSON_READ_ALLOW_COMMENTS | YYJSON_READ_ALLOW_INF_AND_NAN;
        doc = yyjson_read_opts((char *)json, len, default_flg, NULL, &err);
    } else {
        /* Configure yyjson read flags */
        yyjson_read_flag flg = YYJSON_READ_NOFLAG;
        if (opts->allow_comments) flg |= YYJSON_READ_ALLOW_COMMENTS;
        if (opts->allow_nan) flg |= YYJSON_READ_ALLOW_INF_AND_NAN;
        doc = yyjson_read_opts((char *)json, len, flg, NULL, &err);
    }

    if (__builtin_expect(!doc, 0)) {
        /* Parse error - raise Ruby exception with details */
        char error_msg[256];
        snprintf(error_msg, sizeof(error_msg),
                 "Parse error at position %zu: %s",
                 err.pos, err.msg);
        RAISE_PARSE_ERROR(error_msg);
    }

    /* Build Ruby object from the document */
    VALUE result = yyjson_build_ruby_object(doc, opts);

    /* Free the yyjson document */
    yyjson_doc_free(doc);

    return result;
}

/*
 * Parse JSON from a file
 *
 * @param file_path Path to the JSON file
 * @param opts Parse options
 * @return Ruby object representing the parsed JSON
 */
VALUE
yyjson_parse_file(VALUE file_path, const yyjson_parse_options *opts)
{
    /* Ensure we have a string path */
    Check_Type(file_path, T_STRING);
    SafeStringValue(file_path);

    const char *path = RSTRING_PTR(file_path);

    /* Configure yyjson read flags */
    yyjson_read_flag flg = 0;

    if (opts->allow_comments) {
        flg |= YYJSON_READ_ALLOW_COMMENTS;
    }
    if (opts->allow_nan) {
        flg |= YYJSON_READ_ALLOW_INF_AND_NAN;
    }

    /* Parse the JSON file */
    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_file(path, flg, NULL, &err);

    if (!doc) {
        /* Check if file doesn't exist or parse error */
        if (err.code == YYJSON_READ_ERROR_FILE_OPEN) {
            rb_raise(rb_eIOError, "Cannot open file: %s", path);
        } else {
            /* Parse error - raise Ruby exception with details */
            char error_msg[512];
            snprintf(error_msg, sizeof(error_msg),
                     "Parse error in file %s at position %zu: %s (code: %u)",
                     path, err.pos, err.msg, err.code);
            RAISE_PARSE_ERROR(error_msg);
        }
    }

    /* Build Ruby object from the document */
    VALUE result = yyjson_build_ruby_object(doc, opts);

    /* Free the yyjson document */
    yyjson_doc_free(doc);

    return result;
}

/*
 * Extract parse options from a Ruby hash
 *
 * @param opts_hash Ruby hash of options
 * @param opts Output parse options struct
 */
void
yyjson_extract_parse_options(VALUE opts_hash, yyjson_parse_options *opts)
{
    VALUE val;

    /* Set defaults for MODE_COMPAT (the default mode) */
    opts->symbolize_names = false;
    opts->freeze = false;
    opts->allow_nan = true;
    opts->allow_comments = true;
    opts->max_nesting = 100;
    opts->mode = MODE_COMPAT;

    /* If no options hash provided, use defaults */
    if (NIL_P(opts_hash)) {
        return;
    }

    /* First, check for mode and apply mode-specific defaults */
    val = rb_hash_aref(opts_hash, ID2SYM(id_mode));
    if (!NIL_P(val) && SYMBOL_P(val)) {
        ID mode_id = SYM2ID(val);
        if (mode_id == rb_intern("strict")) {
            opts->mode = MODE_STRICT;
            /* MODE_STRICT: strict JSON spec compliance */
            opts->allow_nan = false;
            opts->allow_comments = false;
            opts->symbolize_names = false;
        } else if (mode_id == rb_intern("compat")) {
            opts->mode = MODE_COMPAT;
            /* MODE_COMPAT: JSON gem compatibility (defaults already set) */
        } else if (mode_id == rb_intern("rails")) {
            opts->mode = MODE_RAILS;
            /* MODE_RAILS: Rails/ActiveSupport compatibility */
            opts->symbolize_names = true;
            opts->allow_nan = true;
            opts->allow_comments = true;
        } else if (mode_id == rb_intern("object")) {
            opts->mode = MODE_OBJECT;
            /* MODE_OBJECT: custom object serialization */
        } else if (mode_id == rb_intern("custom")) {
            opts->mode = MODE_CUSTOM;
            /* MODE_CUSTOM: fully customizable */
        }
    }

    /* Then, allow explicit option overrides */
    val = rb_hash_aref(opts_hash, ID2SYM(id_symbolize_names));
    if (!NIL_P(val)) {
        opts->symbolize_names = RTEST(val);
    }

    val = rb_hash_aref(opts_hash, ID2SYM(id_freeze));
    if (!NIL_P(val)) {
        opts->freeze = RTEST(val);
    }

    val = rb_hash_aref(opts_hash, ID2SYM(id_allow_nan));
    if (!NIL_P(val)) {
        opts->allow_nan = RTEST(val);
    }

    val = rb_hash_aref(opts_hash, ID2SYM(id_allow_comments));
    if (!NIL_P(val)) {
        opts->allow_comments = RTEST(val);
    }

    val = rb_hash_aref(opts_hash, ID2SYM(id_max_nesting));
    if (!NIL_P(val)) {
        opts->max_nesting = NUM2INT(val);
    }
}
