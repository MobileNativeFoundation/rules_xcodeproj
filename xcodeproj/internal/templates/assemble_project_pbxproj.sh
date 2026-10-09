#!/bin/bash

# Assembles a `project.pbxproj` from `PBXProj` partials, in the same layout that
# Xcode writes.
#
# Usage: assemble_project_pbxproj.sh <output> <inputs_list>
#
# `inputs_list` is a file containing the paths of the partials, one per line,
# in the order they need to be concatenated.
#
# The partials are concatenated, and the objects inside of `objects = { ... }`
# are re-emitted grouped by their `isa`, in `/* Begin <isa> section */` ...
# `/* End <isa> section */` blocks. Sections are sorted by `isa`, objects
# within a section by identifier, and the attributes of a multi-line object by
# name (with `isa` first), which is how Xcode serializes a project. This also
# lets an object be written in parts by different generators (e.g. the
# `PBXProject`) without them needing to coordinate attribute order.
# Having the file match Xcode byte for byte means Xcode doesn't need to rewrite
# it when it next saves the project (e.g. after a file is added to a
# `PBXFileSystemSynchronizedRootGroup`).
#
# Objects are expected to be formatted the way Xcode formats them: each one
# starts on a line indented with two tabs (`\t\t<id> /* <comment> */ = {...`),
# and is either completely on that line (ending with `};`), or continues on more
# deeply indented lines (with `isa` being the first attribute) until a line
# that is exactly `\t\t};`.
#
# Nested dictionaries (e.g. `buildSettings`) are not reordered; the generators
# write them sorted.
#
# The work is streamed: every line of every object becomes a record keyed by
# `isa`, identifier, and attribute name, and a stable `sort` groups and orders
# the records without reordering lines within an attribute.

set -euo pipefail

readonly output="$1"
readonly inputs_list="$2"

readonly field_separator=$'\037'

footer="$(mktemp "${TMPDIR:-/tmp}/project_pbxproj_footer.XXXXXX")"
readonly footer
trap 'rm -f "$footer"' EXIT

tr '\n' '\0' < "$inputs_list" | xargs -0 cat | \
  LC_ALL=C awk \
    -v FS_="$field_separator" \
    -v header="$output" \
    -v footer="$footer" \
    '
function fail(message) {
  printf "ERROR: Malformed project.pbxproj partials (line %d): %s\n", \
    NR, message > "/dev/stderr"
  failed = 1
  exit 1
}

function emit(line) {
  print isa FS_ id FS_ attribute FS_ line
}

BEGIN {
  # 0: header, 1: objects, 2: footer
  state = 0
  # Whether we are inside of a multi-line object
  in_object = 0
  # Lines of a multi-line object read before its `isa` is known
  pending_count = 0
}

state == 0 {
  print > header
  if ($0 == "\tobjects = {") {
    close(header)
    state = 1
  }
  next
}

state == 2 {
  print > footer
  next
}

# state == 1

$0 == "" { next }

# Section markers are recreated, which makes assembling idempotent
/^\/\* (Begin|End) [A-Za-z0-9_]+ section \*\/$/ { next }

substr($0, 1, 2) == "\t\t" && substr($0, 3, 1) != "\t" {
  if ($0 == "\t\t};") {
    if (!in_object) {
      fail("unexpected end of object")
    }
    if (isa == "") {
      fail("object " id " has no isa")
    }
    attribute = "\177"
    emit($0)
    in_object = 0
    next
  }

  if (in_object) {
    fail("object " id " is not terminated")
  }

  id = $1
  # The first line of an object sorts before all of its attributes
  attribute = ""
  if ($0 ~ /};$/) {
    if (!match($0, /isa = [A-Za-z0-9_]+;/)) {
      fail("object " id " has no isa")
    }
    isa = substr($0, RSTART + 6, RLENGTH - 7)
    emit($0)
    next
  }

  in_object = 1
  isa = ""
  pending[pending_count++] = $0
  next
}

$0 == "\t};" {
  if (in_object) {
    fail("object " id " is not terminated")
  }
  state = 2
  print > footer
  next
}

{
  if (!in_object) {
    fail("unexpected line outside of an object")
  }

  if (isa == "") {
    if (pending_count != 1) {
      fail("isa of object " id " is not its first attribute")
    }
    if (!match($0, /^\t\t\tisa = [A-Za-z0-9_]+;$/)) {
      fail("isa of object " id " is not its first attribute")
    }
    isa = substr($0, 10, length($0) - 10)
    emit(pending[0])
    pending_count = 0
    # `isa` sorts before all other attributes
    attribute = "\001"
    emit($0)
    next
  }

  # A new attribute starts on a line indented with exactly three tabs that
  # is not closing the value of the previous attribute
  if (substr($0, 4, 1) != "\t" && \
      substr($0, 4, 1) != ")" && \
      substr($0, 4, 1) != "}") {
    attribute = substr($0, 4, index($0, " = ") - 4)
    if (attribute == "") {
      fail("unexpected line in object " id)
    }
  }

  emit($0)
}

END {
  if (failed) {
    exit 1
  }
  if (state != 2) {
    fail("missing end of objects")
  }
  close(footer)
}
' | \
  LC_ALL=C sort -s -t "$field_separator" -k1,1 -k2,2 -k3,3 | \
  LC_ALL=C awk \
    -v FS="$field_separator" \
    '
{
  if ($1 != section) {
    if (section != "") {
      print "/* End " section " section */"
    }
    section = $1
    print ""
    print "/* Begin " section " section */"
  }
  print $4
}

END {
  if (section != "") {
    print "/* End " section " section */"
  }
}
' >> "$output"

cat "$footer" >> "$output"
