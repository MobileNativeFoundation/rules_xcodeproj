#!/bin/bash

set -euo pipefail

cd "$SRCROOT"

readonly config="${BAZEL_CONFIG}_indexbuild"

# Compiled outputs (i.e. swiftmodules) and generated inputs
readonly output_groups=(
  "index_import"
  # Compile params
  "bc $BAZEL_TARGET_ID"
  # Products (i.e. bundles) and index store data. The products themselves aren't
  # used, they cause transitive files to be created. We use
  # `--experimental_remote_download_regex` below to collect the files we care
  # about.
  "bp $BAZEL_TARGET_ID"
  # TODO: Remove `bi` once we remove support for legacy generation mode
  "bi $BAZEL_TARGET_ID"
)

readonly targetid_regex='@{0,2}(.*)//(.*):(.*) ([^\ ]+)$'

indexstores_filelists=()
if [[ "$IMPORT_INDEX_BUILD_INDEXSTORES" == "YES" && \
      "$BAZEL_TARGET_ID" =~ $targetid_regex ]]; then
  repo="${BASH_REMATCH[1]}"
  if [[ "$repo" == "@" ]]; then
    repo=""
  fi

  package="${BASH_REMATCH[2]}"
  target="${BASH_REMATCH[3]}"
  configuration="${BASH_REMATCH[4]}"
  filelist="$configuration/bin/${repo:+"external/$repo/"}$package/$target-bi.filelist"

  indexstores_filelists+=("$filelist")
fi

readonly build_pre_config_flags=(
  # Include the following:
  #
  # - .indexstore directories to allow importing indexes
  # - .swift{doc,module,sourceinfo} files for indexing
  # - compilation input files (.cfg, .c, .C .cc, .cl, .cpp, .cu, .cxx, .c++,
  #   .def, .h, .H, .hh, .hpp, .hxx, .h++, .hmap, .ilc, .inc, .ipp, .tcc, .tlh,
  #   .tpp, .m, .modulemap, .mm, .pch, .swift, .yaml) for index compilation
  #
  # This is brittle. If different file extensions are used for compilation
  # inputs, they will need to be added to this list. Ideally we can stop doing
  # this once Bazel adds support for a Remote Output Service.
  "--experimental_remote_download_regex=.*\.indexstore/.*|.*\.(cfg|c|C|cc|cl|cpp|cu|cxx|c++|def|h|H|hh|hpp|hxx|h++|hmap|ilc|inc|inl|ipp|tcc|tlh|tli|tpp|m|modulemap|mm|pch|swift|swiftdoc|swiftmodule|swiftsourceinfo|yaml)$"
)

source "$BAZEL_INTEGRATION_DIR/bazel_build.sh"

# Import indexes
if [ -n "${indexstores_filelists:-}" ]; then
  "$BAZEL_INTEGRATION_DIR/import_indexstores" \
    "$INDEXING_PROJECT_DIR__NO" \
    "${indexstores_filelists[@]/#/$output_path/}"
fi
