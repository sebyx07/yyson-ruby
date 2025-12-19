/*
 * writer.c - JSON document writer
 *
 * Handles writing yyjson mutable documents to JSON strings.
 */

#include "common.h"
#include "object_dumper.h"
#include "writer.h"
#include <string.h>

/*
 * Escape HTML entities in a JSON string
 *
 * Replaces:
 *   < with \u003c
 *   > with \u003e
 *   & with \u0026
 *   ' with \u0027 (for attribute safety)
 *
 * This prevents XSS when JSON is embedded in HTML.
 *
 * @param json The JSON string to escape
 * @param len Length of the JSON string
 * @param out_len Output parameter for escaped string length
 * @return Newly allocated escaped string (caller must free)
 */
static char *
escape_html_entities(const char *json, size_t len, size_t *out_len)
{
    size_t escape_count = 0;
    const char *p = json;
    const char *end = json + len;

    /* First pass: count characters that need escaping */
    while (p < end) {
        char c = *p;
        if (c == '<' || c == '>' || c == '&' || c == '\'') {
            escape_count++;
        }
        p++;
    }

    /* If nothing to escape, return copy */
    if (escape_count == 0) {
        char *result = (char *)malloc(len);
        if (result) {
            memcpy(result, json, len);
            *out_len = len;
        }
        return result;
    }

    /* Allocate new string: each escaped char becomes \uXXXX (6 bytes instead of 1) */
    size_t new_len = len + (escape_count * 5);  /* 5 extra bytes per escaped char */
    char *result = (char *)malloc(new_len);
    if (!result) {
        return NULL;
    }

    /* Second pass: copy and escape */
    const char *src = json;
    char *dst = result;
    while (src < end) {
        char c = *src;
        if (c == '<') {
            memcpy(dst, "\\u003c", 6);
            dst += 6;
        } else if (c == '>') {
            memcpy(dst, "\\u003e", 6);
            dst += 6;
        } else if (c == '&') {
            memcpy(dst, "\\u0026", 6);
            dst += 6;
        } else if (c == '\'') {
            memcpy(dst, "\\u0027", 6);
            dst += 6;
        } else {
            *dst++ = c;
        }
        src++;
    }

    *out_len = dst - result;
    return result;
}

/*
 * Write a Ruby object to a JSON string
 *
 * @param obj The Ruby object to serialize
 * @param opts Dump options
 * @return Ruby string containing JSON
 */
VALUE
yyjson_ruby_write_string(VALUE obj, const yyjson_dump_options *opts)
{
    /* Create mutable document */
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    if (!doc) {
        RAISE_GENERATE_ERROR("Failed to create JSON document");
    }

    /* Dump Ruby object to yyjson mutable value */
    yyjson_mut_val *root = yyjson_dump_ruby_object(obj, doc, opts);
    if (!root) {
        yyjson_mut_doc_free(doc);
        RAISE_GENERATE_ERROR("Failed to convert Ruby object to JSON");
    }

    /* Set document root */
    yyjson_mut_doc_set_root(doc, root);

    /* Configure write flags */
    yyjson_write_flag flg = 0;

    if (opts->pretty) {
        flg |= YYJSON_WRITE_PRETTY;
        flg |= YYJSON_WRITE_PRETTY_TWO_SPACES; /* Use 2-space indent by default */
    }

    if (opts->escape_slash) {
        flg |= YYJSON_WRITE_ESCAPE_SLASHES;
    }

    if (opts->allow_nan) {
        flg |= YYJSON_WRITE_ALLOW_INF_AND_NAN;
    }

    /* Write to string */
    size_t len;
    char *json = yyjson_mut_write_opts(doc, flg, NULL, &len, NULL);

    if (!json) {
        yyjson_mut_doc_free(doc);
        RAISE_GENERATE_ERROR("Failed to write JSON");
    }

    /* Apply HTML entity escaping if requested */
    char *final_json = json;
    size_t final_len = len;

    if (opts->escape_html) {
        char *escaped = escape_html_entities(json, len, &final_len);
        if (!escaped) {
            free(json);
            yyjson_mut_doc_free(doc);
            RAISE_GENERATE_ERROR("Failed to escape HTML entities");
        }
        free(json);  /* Free original JSON */
        final_json = escaped;
    }

    /* Create Ruby string */
    VALUE rb_json = rb_str_new(final_json, final_len);
    rb_enc_associate(rb_json, rb_utf8_encoding());

    /* Clean up */
    free(final_json);
    yyjson_mut_doc_free(doc);

    return rb_json;
}

/*
 * Write a Ruby object to a JSON file
 *
 * @param obj The Ruby object to serialize
 * @param file_path Path to output file
 * @param opts Dump options
 * @return Qnil on success
 */
VALUE
yyjson_ruby_write_file(VALUE obj, VALUE file_path, const yyjson_dump_options *opts)
{
    /* Ensure we have a string path */
    Check_Type(file_path, T_STRING);
    SafeStringValue(file_path);

    const char *path = RSTRING_PTR(file_path);

    /* Create mutable document */
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    if (!doc) {
        RAISE_GENERATE_ERROR("Failed to create JSON document");
    }

    /* Dump Ruby object to yyjson mutable value */
    yyjson_mut_val *root = yyjson_dump_ruby_object(obj, doc, opts);
    if (!root) {
        yyjson_mut_doc_free(doc);
        RAISE_GENERATE_ERROR("Failed to convert Ruby object to JSON");
    }

    /* Set document root */
    yyjson_mut_doc_set_root(doc, root);

    /* Configure write flags */
    yyjson_write_flag flg = 0;

    if (opts->pretty) {
        flg |= YYJSON_WRITE_PRETTY;
        flg |= YYJSON_WRITE_PRETTY_TWO_SPACES;
    }

    if (opts->escape_slash) {
        flg |= YYJSON_WRITE_ESCAPE_SLASHES;
    }

    if (opts->allow_nan) {
        flg |= YYJSON_WRITE_ALLOW_INF_AND_NAN;
    }

    /* Write to file */
    yyjson_write_err err;
    bool success = yyjson_mut_write_file(path, doc, flg, NULL, &err);

    if (!success) {
        yyjson_mut_doc_free(doc);
        char error_msg[256];
        snprintf(error_msg, sizeof(error_msg),
                 "Failed to write JSON to file %s: %s (code: %u)",
                 path, err.msg, err.code);
        RAISE_GENERATE_ERROR(error_msg);
    }

    /* Clean up */
    yyjson_mut_doc_free(doc);

    return Qnil;
}

/*
 * Extract dump options from a Ruby hash
 *
 * @param opts_hash Ruby hash of options
 * @param opts Output dump options struct
 */
void
yyjson_extract_dump_options(VALUE opts_hash, yyjson_dump_options *opts)
{
    VALUE val;

    /* Set defaults */
    opts->pretty = false;
    opts->escape_slash = false;
    opts->allow_nan = true;
    opts->escape_html = false;
    opts->indent = 2;
    opts->mode = MODE_COMPAT;
    opts->temp_obj = NULL;

    /* If no options hash provided, use defaults */
    if (NIL_P(opts_hash)) {
        return;
    }

    /* Extract pretty option */
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("pretty")));
    if (!NIL_P(val)) {
        opts->pretty = RTEST(val);
    }

    /* Extract indent option */
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("indent")));
    if (!NIL_P(val)) {
        opts->indent = NUM2INT(val);
        if (opts->indent > 0) {
            opts->pretty = true;  /* Enable pretty if indent specified */
        }
    }

    /* Extract escape_slash option */
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("escape_slash")));
    if (!NIL_P(val)) {
        opts->escape_slash = RTEST(val);
    }

    /* Extract allow_nan option */
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("allow_nan")));
    if (!NIL_P(val)) {
        opts->allow_nan = RTEST(val);
    }

    /* Extract mode option and apply mode-specific defaults */
    val = rb_hash_aref(opts_hash, ID2SYM(id_mode));
    if (!NIL_P(val) && SYMBOL_P(val)) {
        ID mode_id = SYM2ID(val);
        if (mode_id == rb_intern("strict")) {
            opts->mode = MODE_STRICT;
            opts->allow_nan = false;  /* Strict mode disallows NaN */
            opts->escape_slash = true;  /* Strict mode escapes slashes */
        } else if (mode_id == rb_intern("compat")) {
            opts->mode = MODE_COMPAT;
        } else if (mode_id == rb_intern("rails")) {
            opts->mode = MODE_RAILS;
            opts->escape_html = true;  /* Rails mode escapes HTML by default */
        } else if (mode_id == rb_intern("object")) {
            opts->mode = MODE_OBJECT;
        }
    }

    /* Allow explicit option overrides after mode defaults */
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("escape_html")));
    if (!NIL_P(val)) {
        opts->escape_html = RTEST(val);
    }
}
