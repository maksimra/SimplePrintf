#!/bin/bash

BUILD_FOLDER="build"

set -x
mkdir -p $BUILD_FOLDER

nasm -f elf64 printf.asm -o ${BUILD_FOLDER}/printf.o
ld -s ${BUILD_FOLDER}/prinf.o -o ${BUILD_FOLDER}/printf