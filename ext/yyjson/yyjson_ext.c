/*
 * YYJson - Ultra-fast JSON parser and generator for Ruby
 * Powered by yyjson (https://github.com/ibireme/yyjson)
 */

#include "common.h"
#include "value_builder.h"
#include "parser.h"
#include "object_dumper.h"
#include "writer.h"

/* Module and class definitions */
VALUE mYYJson = Qnil;
VALUE cParser = Qnil;
VALUE eYYJsonError = Qnil;
VALUE eParseError = Qnil;
VALUE eGenerateError = Qnil;

/* Symbol IDs */
ID id_to_json;
ID id_as_json;
ID id_to_hash;
ID id_to_s;
ID id_read;
ID id_new;
ID id_utc;
ID id_symbolize_names;
ID id_freeze;
ID id_mode;
ID id_max_nesting;
ID id_allow_nan;
ID id_allow_comments;
ID id_create_additions;

/* Default parse options (initialized once) */
static yyjson_parse_options default_parse_opts = {
    .symbolize_names = false,
    .freeze = false,
    .allow_nan = true,
    .allow_comments = true,
    .max_nesting = 100,
    .mode = MODE_COMPAT
};

/*
 * YYJson.load(source, opts = {})
 *
 * Parse JSON from a string.
 *
 * Options:
 *   :symbolize_names - Convert hash keys to symbols (default: false)
 *   :freeze - Freeze parsed objects (default: false)
 *   :mode - Parsing mode (:strict, :compat, :rails, :object) (default: :compat)
 *   :max_nesting - Maximum nesting depth (default: 100)
 *   :allow_nan - Allow NaN and Infinity (default: true)
 *   :allow_comments - Allow C-style comments (default: true)
 *
 * Returns the parsed Ruby object.
 */
static VALUE
yyjson_load(int argc, VALUE *argv, VALUE self)
{
    VALUE source, opts;
    rb_scan_args(argc, argv, "11", &source, &opts);

    /* Fast path: no options provided - use defaults */
    if (NIL_P(opts) || RHASH_EMPTY_P(opts)) {
        return yyjson_parse_string(source, &default_parse_opts);
    }

    /* Extract parse options */
    yyjson_parse_options parse_opts;
    yyjson_extract_parse_options(opts, &parse_opts);

    /* Parse the JSON string */
    return yyjson_parse_string(source, &parse_opts);
}

/*
 * YYJson.dump(obj, opts = {})
 *
 * Generate JSON from a Ruby object.
 *
 * Options:
 *   :mode - Generation mode (:strict, :compat, :rails, :object) (default: :compat)
 *   :indent - Indentation string or number of spaces (default: nil for compact)
 *   :pretty - Pretty print (default: false)
 *   :escape_slash - Escape forward slashes (default: false)
 *
 * Returns a JSON string.
 */
static VALUE
yyjson_dump(int argc, VALUE *argv, VALUE self)
{
    VALUE obj, opts;
    rb_scan_args(argc, argv, "11", &obj, &opts);

    if (NIL_P(opts)) {
        opts = rb_hash_new();
    }

    /* Extract dump options */
    yyjson_dump_options dump_opts;
    yyjson_extract_dump_options(opts, &dump_opts);

    /* Generate JSON string */
    return yyjson_ruby_write_string(obj, &dump_opts);
}

/*
 * YYJson.parse(source, opts = {})
 *
 * Alias for YYJson.load for JSON gem compatibility.
 */
static VALUE
yyjson_parse(int argc, VALUE *argv, VALUE self)
{
    return yyjson_load(argc, argv, self);
}

/*
 * YYJson.generate(obj, opts = {})
 *
 * Alias for YYJson.dump for JSON gem compatibility.
 */
static VALUE
yyjson_generate(int argc, VALUE *argv, VALUE self)
{
    return yyjson_dump(argc, argv, self);
}

/*
 * YYJson.load_file(path, opts = {})
 *
 * Parse JSON from a file.
 */
static VALUE
yyjson_load_file(int argc, VALUE *argv, VALUE self)
{
    VALUE path, opts;
    rb_scan_args(argc, argv, "11", &path, &opts);

    SafeStringValue(path);

    if (NIL_P(opts)) {
        opts = rb_hash_new();
    }

    /* Extract parse options */
    yyjson_parse_options parse_opts;
    yyjson_extract_parse_options(opts, &parse_opts);

    /* Parse the JSON file */
    return yyjson_parse_file(path, &parse_opts);
}

/*
 * YYJson.dump_file(obj, path, opts = {})
 *
 * Generate JSON and write to a file.
 */
static VALUE
yyjson_dump_file(int argc, VALUE *argv, VALUE self)
{
    VALUE obj, path, opts;
    rb_scan_args(argc, argv, "21", &obj, &path, &opts);

    SafeStringValue(path);

    if (NIL_P(opts)) {
        opts = rb_hash_new();
    }

    /* Extract dump options */
    yyjson_dump_options dump_opts;
    yyjson_extract_dump_options(opts, &dump_opts);

    /* Write JSON to file */
    return yyjson_ruby_write_file(obj, path, &dump_opts);
}

/*
 * Initialize the YYJson extension.
 */
void
Init_yyjson(void)
{
    /* Define module */
    mYYJson = rb_define_module("YYJson");

    /* Define exception classes */
    eYYJsonError = rb_define_class_under(mYYJson, "Error", rb_eStandardError);
    eParseError = rb_define_class_under(mYYJson, "ParseError", eYYJsonError);
    eGenerateError = rb_define_class_under(mYYJson, "GenerateError", eYYJsonError);

    /* Define module methods */
    rb_define_singleton_method(mYYJson, "load", yyjson_load, -1);
    rb_define_singleton_method(mYYJson, "dump", yyjson_dump, -1);
    rb_define_singleton_method(mYYJson, "parse", yyjson_parse, -1);
    rb_define_singleton_method(mYYJson, "generate", yyjson_generate, -1);
    rb_define_singleton_method(mYYJson, "load_file", yyjson_load_file, -1);
    rb_define_singleton_method(mYYJson, "dump_file", yyjson_dump_file, -1);

    /* Initialize symbol IDs for common operations */
    id_to_json = rb_intern("to_json");
    id_as_json = rb_intern("as_json");
    id_to_hash = rb_intern("to_hash");
    id_to_s = rb_intern("to_s");
    id_read = rb_intern("read");
    id_new = rb_intern("new");
    id_utc = rb_intern("utc");

    /* Initialize option symbol IDs */
    id_symbolize_names = rb_intern("symbolize_names");
    id_freeze = rb_intern("freeze");
    id_mode = rb_intern("mode");
    id_max_nesting = rb_intern("max_nesting");
    id_allow_nan = rb_intern("allow_nan");
    id_allow_comments = rb_intern("allow_comments");
    id_create_additions = rb_intern("create_additions");

    /* Initialize value builder */
    yyjson_value_builder_init();

    /* TODO: Initialize Parser class */
    /* cParser = rb_define_class_under(mYYJson, "Parser", rb_cObject); */
}
