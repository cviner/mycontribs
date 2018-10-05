#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit

# Usage: ./delete_fields.sh <input.bib> <journal abbreviation>

# Deletes specific fields from the input Bib(La)TeX file.
# Outputs the resulting Bib(La)TeX file to STDOUT.

# Currently only permits selection from pre-defined journal abbreviations, to remove fields that those journals do not permit in their reference lists (but for which implementing at the level of BibTeX or Biber is prohibitively difficult).

# Supported journals and abbreviations:
#
# - "nar" - Nucleic Acids Research

ERR_EXIT=64

INPUT_BIB_FILE="$1"

BIBTOOL_DEL_ARG='delete.field'

# files to delete after
temp_files_to_del=()

# fields will be removed
fields_to_del=()

# any additional journal-specific parameters
additional_params_arg=''

case "$2" in
    'nar')
        # TODO not possible at present; see: https://github.com/ge-ne/bibtool/issues/33
        # replace the "pages" field with the "number", if it never had any pages defined (e.g. electronic articles with only article numbers)
        #additional_params='rename.field {number=pages if not pages}'
        #
        # workaround: two runs of BibTool to process after selection with and without "number"

        # XXX Does not currently handle case of only "number", with no "volume" nor "pages" fields.
        #     This needs to be manually fixed (by changing "number" to "volume" in these cases).
        #     This mainly applies to bioRxiv pre-prints.

        split_field='pages'

        bibtool -- "select{$split_field ".+"}" -o "temp-$split_field.bib" "$INPUT_BIB_FILE"
        bibtool -- "select.non{$split_field \".+\"}" -o "temp-no-$split_field.bib" "$INPUT_BIB_FILE"

        # begin removal of the "number" field

        # 1) for entries without any pages, rename any "number" field to "pages"
        bibtool -- "rename.field {number=$split_field}" -o "temp-no-$split_field-renamed.bib" "temp-no-$split_field.bib"

        # 2) merge the files (renamed with unaltered entires with pages), making that the new input file
        INPUT_BIB_FILE="temp-merged.bib"
        bibtool -o "$INPUT_BIB_FILE" "temp-$split_field.bib" "temp-no-$split_field-renamed.bib"

        # 3) instruct the main BibTool command below to remove the "number" field (and any others)
        fields_to_del=(number month)

        # 4) instruct the main BibTool command below to add an entryType field
        additional_params_arg='-- "add.field {entryType=\"%s(\$type)\"}"'
        # TODO NB: need to manually change "url" to "howpublished", since unable to use BibTool to replace with "\url{...}" (below does "\url[...]")
        #-- "rewrite.rule {url # \"{\(.*\)}\" # \"\\\url[\\1\]\" }" -- "rename.field {url=howpublished}"

        # 5) mark the temporary files for deletion
        temp_files_to_del=("temp-$split_field.bib" "temp-no-$split_field.bib" "temp-no-$split_field-renamed.bib" "temp-merged.bib")
    ;;
    *)
        >&2 echo "Unrecognized journal abbreviation."
        exit $ERR_EXIT
esac

fields_to_del_args=""
# construct delete.field arguments
for field in "${fields_to_del[@]}"; do
    fields_to_del_args="${fields_to_del_args} -- '$BIBTOOL_DEL_ARG {$field}'"
done

echo "$fields_to_del_args" | parallel -j 1 bibtool "$additional_params_arg" "$INPUT_BIB_FILE"

rm -f "${temp_files_to_del[@]}"

