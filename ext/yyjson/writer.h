/*
 * writer.h - JSON document writer
 */

#ifndef YYJSON_RUBY_WRITER_H
#define YYJSON_RUBY_WRITER_H

#include "common.h"
#include "object_dumper.h"

/*
 * Write a Ruby object to a JSON string
 *
 * @param obj The Ruby object to serialize
 * @param opts Dump options
 * @return Ruby string containing JSON
 */
VALUE yyjson_ruby_write_string(VALUE obj, const yyjson_dump_options *opts);

/*
 * Write a Ruby object to a JSON file
 *
 * @param obj The Ruby object to serialize
 * @param file_path Path to output file
 * @param opts Dump options
 * @return Qnil on success
 */
VALUE yyjson_ruby_write_file(VALUE obj, VALUE file_path, const yyjson_dump_options *opts);

/*
 * Extract dump options from a Ruby hash
 *
 * @param opts_hash Ruby hash of options
 * @param opts Output dump options struct
 */
void yyjson_extract_dump_options(VALUE opts_hash, yyjson_dump_options *opts);

#endif /* YYJSON_RUBY_WRITER_H */
