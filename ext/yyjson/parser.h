/*
 * parser.h - yyjson document wrapper and parsing functions
 */

#ifndef YYJSON_RUBY_PARSER_H
#define YYJSON_RUBY_PARSER_H

#include "common.h"
#include "value_builder.h"

/*
 * Parse JSON from a string
 *
 * @param json_str The JSON string to parse
 * @param opts Parse options
 * @return Ruby object representing the parsed JSON
 */
VALUE yyjson_parse_string(VALUE json_str, const yyjson_parse_options *opts);

/*
 * Parse JSON from a file
 *
 * @param file_path Path to the JSON file
 * @param opts Parse options
 * @return Ruby object representing the parsed JSON
 */
VALUE yyjson_parse_file(VALUE file_path, const yyjson_parse_options *opts);

/*
 * Extract parse options from a Ruby hash
 *
 * @param opts_hash Ruby hash of options
 * @param opts Output parse options struct
 */
void yyjson_extract_parse_options(VALUE opts_hash, yyjson_parse_options *opts);

#endif /* YYJSON_RUBY_PARSER_H */
