#!/bin/bash

for expect in $expected; do
  if [[ -z "${!expect}" ]]; then
    echo "Missing environment variable: $expect"
    echo "Expected: $expected"
    exit 1
  fi
done