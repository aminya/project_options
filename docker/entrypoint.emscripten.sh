#!/usr/bin/env bash
set -e

source ~/.cpprc

# Activate PATH and other environment variables in the current terminal
source /root/emsdk/emsdk_env.sh

exec "$@"