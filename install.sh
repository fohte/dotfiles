#!/bin/bash

is_macos() {
  [[ $OSTYPE == darwin* ]]
}

if is_macos; then
  ./.bootstrap/macos/setup.sh
fi
