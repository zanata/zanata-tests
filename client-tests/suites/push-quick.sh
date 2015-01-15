CLASSNAME=push
SUMMARY="push frequently used options"

mkdir -p ${WORK_DIR}
cd $WORK_DIR

COMMON_OPTIONS=("--url=${ZANATA_URL}" "--username=${ZANATA_USERNAME}" "--key=${ZANATA_KEY}")
COMPULSORY_OPTIONS=()

## Compulsory options Only
TestCaseStart "CompulsoryOptions Only"
RunCmd  ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} 
OutputNoError

## Push type trans
TestCaseStart "pushType=trans"
RunCmd ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} --push-type=trans
OutputNoError

## Push type both
TestCaseStart "pushType=both"
RunCmd ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} --push-type=both
OutputNoError


