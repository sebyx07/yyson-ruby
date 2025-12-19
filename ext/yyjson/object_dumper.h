/*
 * object_dumper.h - Ruby to JSON object conversion
 */

#ifndef YYJSON_RUBY_OBJECT_DUMPER_H
#define YYJSON_RUBY_OBJECT_DUMPER_H

#include "common.h"

/*
 * Dump options for controlling how Ruby objects are converted to JSON
 */
typedef struct {
    bool pretty;             /* Pretty print with indentation */
    bool escape_slash;       /* Escape forward slashes */
    bool allow_nan;          /* Allow NaN and Infinity values */
    bool escape_html;        /* Escape HTML entities (<, >, &, ') for XSS prevention */
    int indent;              /* Number of spaces for indentation (0 = compact) */
    yyjson_mode_t mode;      /* Generation mode */
    void *temp_obj;          /* Temporary storage for context passing */
} yyjson_dump_options;

/*
 * Dump a Ruby object to a yyjson mutable value
 *
 * @param obj The Ruby object to convert
 * @param doc The yyjson mutable document to use
 * @param opts Dump options controlling the conversion
 * @return A yyjson mutable value representing the object
 */
yyjson_mut_val *yyjson_dump_ruby_object(VALUE obj, yyjson_mut_doc *doc, const yyjson_dump_options *opts);

#endif /* YYJSON_RUBY_OBJECT_DUMPER_H */
