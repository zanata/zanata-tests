CLASSNAME=push
SUMMARY="push frequently used options"

USE_DEFAULT_OPTIONS=1
PUSH_ORIG_OPTIONS=("${PUSH_OPTIONS[@]}")

## Compulsory options Only
TEST_CASE_NAME_PREFIX="Compulsory options"
source ${SUITE_DIR}/push.sh

## Push type trans
TEST_CASE_NAME_PREFIX="pushType=trans"
PUSH_OPTIONS=( "${PUSH_ORIG_OPTIONS[@]}" --push-type=trans)
source ${SUITE_DIR}/push.sh

## Push type both
TEST_CASE_NAME_PREFIX="pushType=both"
PUSH_OPTIONS=( "${PUSH_ORIG_OPTIONS[@]}" --push-type=both)
source ${SUITE_DIR}/push.sh

## Restore PUSH_OPTIONS
PUSH_OPTIONS=("${PUSH_ORIG_OPTIONS[@]}")
