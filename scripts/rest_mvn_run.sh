#!/bin/bash
ctest -R "rest_mvn.*"
mkdir -p results
scripts/CTest2JUnit -o results/rest_mvn.xml .

