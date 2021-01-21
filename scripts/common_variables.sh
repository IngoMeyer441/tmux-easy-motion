#!/usr/bin/env bash

if [[ -z "${TMPDIR}" ]]; then
    TMPDIR="$(dirname "$(mktemp "tmp.XXXXXXXXXX" -ut)")"
fi
TARGET_KEY_PIPENAME="target_key.pipe"
