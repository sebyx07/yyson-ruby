/*
 * value_builder.h - JSON to Ruby object conversion
 */

#ifndef YYJSON_RUBY_VALUE_BUILDER_H
#define YYJSON_RUBY_VALUE_BUILDER_H

#include "common.h"

/*
 * Parse options for controlling how JSON is converted to Ruby objects
 */
typedef struct {
    bool symbolize_names;    /* Convert hash keys to symbols */
    bool freeze;             /* Freeze strings and collections */
    bool allow_nan;          /* Allow NaN and Infinity values */
    bool allow_comments;     /* Allow C-style comments in JSON */
    int max_nesting;         /* Maximum nesting depth (0 = unlimited) */
    yyjson_mode_t mode;      /* Parsing mode (strict, compat, rails, object) */
} yyjson_parse_options;

/*
 * Initialize the value builder module
 */
void yyjson_value_builder_init(void);

/*
 * Build a Ruby object from a yyjson document
 *
 * @param doc The yyjson document to convert
 * @param opts Parse options controlling the conversion
 * @return A Ruby object representing the JSON data
 */
VALUE yyjson_build_ruby_object(yyjson_doc *doc, const yyjson_parse_options *opts);

#endif /* YYJSON_RUBY_VALUE_BUILDER_H */
