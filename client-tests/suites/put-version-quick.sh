CLASSNAME=put-version
SUMMARY="put-version frequently used options"

mkdir -p ${WORK_DIR}
cd $WORK_DIR

COMMON_OPTIONS=("--url=${ZANATA_URL}" "--username=${ZANATA_USERNAME}" "--key=${ZANATA_KEY}")
COMPULSORY_OPTIONS=("--version-project=${ZANATA_PROJECT_SLUG}" "--version-slug=${ZANATA_VERSION_SLUG}")

## Compulsory options Only
TestCaseStart "CompulsoryOptions Only"
RunCmd ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} 
OutputNoError

