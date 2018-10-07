#!/bin/bash

set -e

cd "$(dirname "$0")"

scripts/install_ansible.sh

ansible-playbook -i ./hosts ./local_env.yml --ask-become-pass -vv
