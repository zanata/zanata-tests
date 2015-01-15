CLASSNAME=put-project
SUMMARY="put-project frequently used options"

mkdir -p ${WORK_DIR}
cd $WORK_DIR

COMMON_OPTIONS=("--url=${ZANATA_URL}" "--username=${ZANATA_USERNAME}" "--key=${ZANATA_KEY}")
COMPULSORY_OPTIONS=("--project-slug=${ZANATA_PROJECT_SLUG}" "--project-name=${ZANATA_PROJECT_NAME}" "--project-desc=${ZANATA_PROJECT_DESC}" "--default-project-type=${ZANATA_PROJECT_TYPE}")

## Compulsory options Only
TestCaseStart "CompulsoryOptions Only"
RunCmd ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} 
OutputNoError

