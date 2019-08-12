#!/usr/bin/env bash

set -eu

n=10000

control_file=perf_control.tmp.adoc
perf_file=perf.tmp.adoc
stem_file=perf_stem.tmp.adoc

printf '= test
:idprefix:
:idseparator: -
:katex-font-size: 1.5em
:katex-version: 0.10.2
:nofooter:
:sectanchors:
:sectlinks:
:sectnumlevels: 6
:sectnums:
:stem:
:toc-title:
:toc: macro
:toclevels: 6

' | tee "$perf_file" | tee "$control_file" | tee "$stem_file" > /dev/null

i=0
while [ "$i" -lt "$n" ]; do
  printf "== header ${i}\n\n" | tee -a "$perf_file" | tee -a "$control_file" | tee -a "$stem_file" > /dev/null
  printf "[katex]\n....\n\\sqrt{${i}+${i}}\n....\n\n" >> "$perf_file"
  printf "asdf ${i}\n\n" >> "$control_file"
  printf "[latexmath]\n++++\n\\sqrt{${i}+${i}}\n++++\n\n" >> "$stem_file"
  i=$(($i+1))
done
printf "performance test with ${n} equations\n"
time asciidoctor --require "$(pwd)/lib/asciidoctor-katex-2.rb" "$perf_file"
printf "\ncontrol without equations\n"
time asciidoctor --require "$(pwd)/lib/asciidoctor-katex-2.rb" "$control_file"
printf "\ncontrol without latexmath\n"
time asciidoctor --require "$(pwd)/lib/asciidoctor-katex-2.rb" "$stem_file"
printf "\nsee if it loads instantly on browser:\n"
chromium-browser "file://$(pwd)/${perf_file%.*}.html#header-$(($n / 2))"
chromium-browser "file://$(pwd)/${control_file%.*}.html#header-$(($n / 2))"
chromium-browser "file://$(pwd)/${stem_file%.*}.html#header-$(($n / 2))"
