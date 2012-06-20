#!/bin/bash
ctest -T Test -R "rest_mvn.*"
mkdir -p results
scripts/CTest2JUnit.pl -o results/rest_mvn.xml .

