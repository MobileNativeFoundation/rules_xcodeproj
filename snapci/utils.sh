#!/usr/bin/env bash

function escape_sashes() {
    echo "$1" | sed 's/\//\\\//g'
}

function post_comment() {
    comment_msg=${1:-}
    if [ -z "$comment_msg" ]; then
        echo "Comment message must be set"
        exit 1
    fi

    git_sha=$(git rev-parse --short HEAD) || exit 1
    echo "Posting Github comment on $git_sha..."

    repo_name=$(git config --get remote.origin.url | awk -F"[\.\/]" '{ print $4}') || exit 1
    curl -s -H "Authorization: token ${GITHUB_APIKEY}" -H "Content-Type: application/json" \
        -X POST -d "{\"body\": \"${comment_msg}\"}" \
        https://github.sc-corp.net/api/v3/repos/Snapchat/${repo_name}/issues/${pull_number}/comments
}

function build_and_test() {
    echo "Building and testing rules_xcodeproj..."
    bzl build //distribution:release # build release package
    bzl test //... # run tests
}
