#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit

# ----------------------------------------------------------------------------

# Runs BibTool to process BibLaTeX references in "*.bib" (within the CWD), to conform to the Hoffman Lab BibLaTeX specification.
# Input: ./*.bib (including ./refs.bib, if it already existed; excludes the defined abbreviations file, usually "abbreviations.bib")
# Required parameter(s): None
# Optional parameter(s): any non-empty first argument will preserve keys, and not regenerate them. Sorting will be applied to the existing keys and (attempted) duplicate removal will still be conducted.
# Output: ./refs.bib (overwritten, if it already existed)

# ----------------------------------------------------------------------------

PRESERVE_KEYS=${1-}

ABBREV_FILE='abbreviations.bib'

ALIAS_FILE='aliases.bib'

OUTPUT_FILE='refs.bib'

# Selected BibLaTeX and custom entry types
# variants encoding all cases that may be used should be added
NEW_ENTRIES=(Online online patent Patent software Software personalcommunication)

# Ignore: web location prefixes, definite and indefinite articles, interrogative words (including "are", used interrogatively), and prepositions
IGNORE_WORDS=(http https ftp sftp are who what where when why how to on at in for before until by on)

# ----------------------------------------------------------------------------

ERR_EXIT=64

NOT_FOUND_REGEX="not found"

BIBTOOL_URL='http://www.gerd-neugebauer.de/software/TeX/BibTool/index.en.html'

version_info=$(bibtool -V 2>&1 || true)
if [[ $version_info =~ $NOT_FOUND_REGEX ]]; then
    >&2 echo "Install Bibtool ($BIBTOOL_URL)."
    exit $ERR_EXIT
else
    >&2 echo "$version_info"
    printf '%.0s-' {1..40}; echo
fi

NEW_ENTRY_PARAMS=""
for word in "${NEW_ENTRIES[@]}"; do
    NEW_ENTRY_PARAMS="$NEW_ENTRY_PARAMS -- 'new.entry.type=\"$word\"'"
done

BIBTOOL_CMD_BASE="bibtool -s -m $ABBREV_FILE -- 'check.double.delete = on' $NEW_ENTRY_PARAMS"

KEY_CONS_PARAMS=""
if [[ -z "$PRESERVE_KEYS" ]]; then
    KEY_CONS_PARAMS=$'-- \'new.format.type {0=\"%*1l\"}\' -- \'fmt.et.al=\"\"\' -f \'{%-1n(author)#%-1n(editor)#}:{%-W(title)#%-W(howpublished)#%-W(url)#}\' -- \'fmt.word.separator=\"\"\' -- \'key.make.alias=on\''
else
    >&2 echo "Citation keys will not be altered."
fi

IGNORE_WORDS_PARAMS=""
for word in "${IGNORE_WORDS[@]}"; do
   IGNORE_WORDS_PARAMS="$IGNORE_WORDS_PARAMS -- 'ignored.word=\"$word\"'"
done

shopt -s extglob
eval "$BIBTOOL_CMD_BASE -@ -- '"'rewrite.rule={"^\"\([^#]*\)\"$" "{\1}"}'"' $KEY_CONS_PARAMS $IGNORE_WORDS_PARAMS -i +(!(abbreviations).bib) -o $OUTPUT_FILE"
shopt -u extglob

fgrep '@ALIAS' $OUTPUT_FILE > $ALIAS_FILE
sed -i '/@ALIAS.*/d' $OUTPUT_FILE

# remove suffixes comprised of only a dash followed by an article
for file in $OUTPUT_FILE $ALIAS_FILE; do
    # reverse before and after to replace only last occurrence (for alias file)
    rev "$file" | sed -r 's/^(,|\}[[:space:]]*)(a|an|the)[-–—]([[:alnum:]]+:[[:alnum:]]+[[:space:]]*(=.*)?\{.*@)/\1\3/' | rev > "$file"-temp
    mv -f "$file"-temp "$file"
done

# remove any aliases containing an identity mapping
# the previous command creates some of these each run (this is an inefficient, but convenient means of fixing that)
grep -Pv "^@ALIAS{(.+?)\s*=\g1\s*}$" "$ALIAS_FILE" > "$ALIAS_FILE-temp"
mv -f "$ALIAS_FILE-temp" "$ALIAS_FILE"

sed -ri 's/—/---/' $OUTPUT_FILE  # use LaTeX em-dashes

>&2 echo "Output merged reference file to \"$OUTPUT_FILE\"."

if [[ ! -s $ABBREV_FILE ]]; then # remove abbrev. file if empty
    rm -f $ABBREV_FILE
fi

