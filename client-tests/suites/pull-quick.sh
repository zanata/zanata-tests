CLASSNAME=pull
SUMMARY="pull frequently used options"

mkdir -p ${WORK_DIR}
cd $WORK_DIR

COMMON_OPTIONS=("--url=${ZANATA_URL}" "--username=${ZANATA_USERNAME}" "--key=${ZANATA_KEY}")
COMPULSORY_OPTIONS=()

## Compulsory options Only
TestCaseStart "CompulsoryOptions Only"
RunCmd  ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} 
OutputNoError

## Push type trans
TestCaseStart "pullType=source"
RunCmd ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} --pull-type=source
OutputNoError

## Push type both
TestCaseStart "pullType=both"
RunCmd ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} --pull-type=both
OutputNoError



