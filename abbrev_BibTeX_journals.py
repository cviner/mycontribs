#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Adapted from: https://gist.github.com/peci1/4e67f3d0521ce014fc952bcca664b37d/f08145ef6f9b1abec6212925572c6fe290540703
# Author: Martin Pecka
# Derivative of original GitHub Gist by Filip Dominec: https://gist.github.com/FilipDominec/9ff081952dbc4aae1df657a56c3db4ea
# Originally described at: http://tex.stackexchange.com/a/303068

from __future__ import with_statement, division, print_function

import sys
import os
import re
import urllib

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

j_list_path = 'journalList.txt'

try:
    bibtexdb = open(sys.argv[1]).read()
except:
    print("Error: specify the file to be processed!")

# Get list of journal abbreviations if not already present
if not os.path.isfile(j_list_path):
    if os.path.isfile(os.path.join(SCRIPT_DIR, j_list_path)):
        j_list_path = os.path.join(SCRIPT_DIR, j_list_path)
    else:
        urllib.urlretrieve("https://raw.githubusercontent.com/JabRef/jabref/master/src/main/resources/journals/" + j_list_path,
                           filename=j_list_path)

rulesfile = open(j_list_path)

# reversed alphabetical order matches extended journal names first
for rule in rulesfile.readlines()[::-1]:
    pattern1, pattern2 = rule.strip().split(" = ")
    # avoid mere abbreviations
    if pattern1 != pattern1.upper() and (' ' in pattern1):
        pattern1_for_display = pattern1

        pattern1 = re.escape(pattern1)
        pattern1 = pattern1.replace('\ ', '\s+')

        repl = re.compile(pattern1, re.IGNORECASE | re.MULTILINE)

        (bibtexdb, num_subs) = repl.subn(pattern2, bibtexdb)

        if num_subs > 0:
            print("Replacing '{}' FOR '{}'".format(pattern1_for_display,
                                                   pattern2))

with open('abbreviated.bib', 'w') as outfile:
    outfile.write(bibtexdb)
    print("Bibtex database with abbreviated files"
          "saved into 'abbreviated.bib'")
