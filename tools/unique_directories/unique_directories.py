#!/usr/bin/python3

import os
import sys

def _insert_into_trie(trie, components):
    if not components:
        return
    _insert_into_trie(trie.setdefault(components[0], {}), components[1:])

def _trie_to_list(trie, prefix_components, output):
    for component, sub_trie in trie.items():
        if not sub_trie:
            output.append(os.sep.join(prefix_components + [component]))
        else:
            _trie_to_list(sub_trie, prefix_components + [component], output)

def _main(input_filelist, output_filelist):
    trie = {}

    with open(input_filelist, 'r', encoding='utf-8') as fp:
        for directory in fp:
            _insert_into_trie(trie, directory.rstrip().split(os.sep))

    directories = []
    _trie_to_list(trie, [], directories)

    with open(output_filelist, 'w', encoding='utf-8') as fp:
        fp.write("\n".join(directories))
        fp.write("\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: unique_directories.py <input.filelist> <output.filelist>")
        exit(1)

    _main(sys.argv[1], sys.argv[2])
