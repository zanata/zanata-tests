#!/bin/bash
ctest -j -V -T Test -R "client_mvn.*"
mkdir -p results
scripts/CTest2JUnit.pl -o results/rest_mvn.xml .

