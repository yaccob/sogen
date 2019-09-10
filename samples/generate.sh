#!/usr/bin/env sh

for f in {xs,s,m,l,xl}.sogen; do sogen $f >${f%sogen}sh; chmod +x ${f%sogen}sh; done
