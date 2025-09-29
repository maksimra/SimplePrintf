#!/bin/bash

BUILD_FOLDER="build"

set -x
mkdir -p $BUILD_FOLDER

nasm -f elf64 -g printf.asm -o ${BUILD_FOLDER}/printf.o
gcc -no-pie -g user.c build/printf.o -Wl,-z,noexecstack -o build/prog