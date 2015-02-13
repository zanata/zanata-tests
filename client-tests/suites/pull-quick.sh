CLASSNAME=pull
SUMMARY="pull frequently used options"

USE_DEFAULT_OPTIONS=1
PULL_ORIG_OPTIONS=("${PULL_OPTIONS[@]}")

## Compulsory options Only
TEST_CASE_NAME_PREFIX="Compulsory options"
source ${SUITE_DIR}/pull.sh

## Pull type trans
TEST_CASE_NAME_PREFIX="pullType=source"
PULL_OPTIONS=( "${PULL_ORIG_OPTIONS[@]}" --pull-type=source)
source ${SUITE_DIR}/pull.sh

## Pull type both
TEST_CASE_NAME_PREFIX="pullType=both"
PULL_OPTIONS=( "${PULL_ORIG_OPTIONS[@]}" --pull-type=both)
source ${SUITE_DIR}/pull.sh

## Restore PULL_OPTIONS
PULL_OPTIONS=("${PULL_ORIG_OPTIONS[@]}")
