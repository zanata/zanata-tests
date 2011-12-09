####################################################################
# REST tests
####################################################################
#===================================================================
# Base requirement
#

MACRO(REQUIRE_CMD var cmd)
    FIND_PROGRAM(${var} "${cmd}" ${ARGN})
    IF("${${var}}" MATCHES "NOTFOUND$")
	MESSAGE(FATAL "${cmd} is not installed")
    ENDIF("${${var}}" MATCHES "NOTFOUND$")
ENDMACRO(REQUIRE_CMD var cmd)

REQUIRE_CMD(PUBLICAN_CMD publican)
REQUIRE_CMD(ZANATA_MVN_CMD mvn)

# ZANATA_PY_PATH: The preferred location of zanata.
IF(NOT "${ZANATA_PY_PATH}" STREQUAL "")
    IF(NOT EXISTS ${ZANATA_PY_PATH})
	# Clone the python client if ZANATA_PY_PATH does not exist.
	FILE(MAKE_DIRECTORY ${ZANATA_PY_PATH})
	EXECUTE_PROCESS(COMMAND git clone ${PYTHON_CLIENT_REPO} ${ZANATA_PY_PATH})
    ENDIF(NOT EXISTS ${ZANATA_PY_PATH})
    # Update python client.
    ADD_CUSTOM_TARGET(python_client_update
	COMMAND git pull
	COMMAND git rev-parse
	COMMAND make clean
	COMMAND make
	COMMENT "Update python client"
	WORKING_DIRECTORY ${ZANATA_PY_PATH}
	)
ENDIF(NOT "${ZANATA_PY_PATH}" STREQUAL "")
REQUIRE_CMD(ZANATA_PY_CMD zanata HINTS ${ZANATA_PY_PATH} /usr/bin /bin NO_DEFAULT_PATH)



ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR_ABSOLUTE}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${SAMPLE_PROJ_DIR_ABSOLUTE}
    )

ADD_CUSTOM_TARGET(prepare_all_projects
    COMMENT "Prepare all projects"
    )



#===================================================================
# Macros
#
MACRO(REST_VERIFY proj ver projType client baseDir pullDest)
    # Note that verifing properties projects is not implemented yet
    # MESSAGE("proj=${proj} ver=${ver} projType=|${projType}| client=${client}")
    IF("${projType}" STREQUAL "podir")
	ADD_CUSTOM_TARGET(rest_verify_${client}_${proj}_${ver}
	    COMMAND scripts/compare_translation_dir.sh
	    ${baseDir}/${SRC_DIR}
	    ${baseDir}/${TRANS_DIR} ${_pull_dest_dir_${client}} "${LANGS}"
	    COMMENT "  [${client}] Verifying the pulled contents with original translation."
	    VERBATIM
	    )
    ELSEIF("${projType}" STREQUAL "gettext")
	ADD_CUSTOM_TARGET(rest_verify_${client}_${proj}_${ver}
		COMMAND scripts/compare_translation_dir.sh -g
		${baseDir}/${${proj}_POT}
		${baseDir}/${TRANS_DIR} ${pullDest} "${LANGS}"
		COMMENT "  [${client}] Verifying the pulled contents with original translation."
		VERBATIM
		)
    ELSE("${projType}" STREQUAL "podir")
	# Verification on other project types are not supported yet
	ADD_DEPENDENCIES(rest_test_${client}_${proj}_${ver} zanata_pull_${client}_${proj}_${ver})
    ENDIF("${projType}" STREQUAL "podir")

    IF(TARGET rest_verify_${client}_${proj}_${ver})
	ADD_DEPENDENCIES(rest_test_${client}_${proj}_${ver} rest_verify_${client}_${proj}_${ver})
	ADD_DEPENDENCIES(rest_verify_${client}_${proj}_${ver} zanata_pull_${client}_${proj}_${ver})
    ENDIF(TARGET rest_verify_${client}_${proj}_${ver})
ENDMACRO(REST_VERIFY proj ver projType client)

MACRO(SET_LOCAL_VARS proj ver client)
    SET(_proj_ver_dir_absolute
	${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/${ver})
    SET(_proj_ver_base_dir_absolute
	${_proj_ver_dir_absolute}/${${proj}_BASE_DIR})
    SET(_proj_ver_publican_cfg_absolute
	${_proj_ver_base_dir_absolute}/publican.cfg)

    IF(NOT "${client}" STREQUAL "src")
	SET(_pull_dest_dir_absolute ${PULL_DEST_DIR_ABSOLUTE}/${client}/${proj}/${_ver})
    ENDIF(NOT "${client}" STREQUAL "src")

    IF(${proj}_ZANATA_XML})
        SET(_zanata_xml_path ${_proj_ver_dir_absolute}/${${proj}_ZANATA_XML})
    ELSE(${proj}_ZANATA_XML})
        SET(_zanata_xml_path ${_proj_ver_dir_absolute}/${ZANATA_XML_DEFAULT})
    ENDIF(${proj}_ZANATA_XML})

    IF("${${proj}_PROJECT_TYPE}" STREQUAL "")
        SET(_projType ${PROJECT_TYPE_DEFAULT})
    ELSE("${${proj}_PROJECT_TYPE}" STREQUAL "")
        SET(_projType ${${proj}_PROJECT_TYPE})
    ENDIF("${${proj}_PROJECT_TYPE}" STREQUAL "")
ENDMACRO(SET_LOCAL_VARS proj ver)


#===================================================================
# Source project targets
#
MACRO(ADD_SOURCE_PROJECT proj)
    SET(_projVers "${${proj}_VERS}")
    SET(_target "")
    IF(NOT ${ARGN} STREQUAL "")
	SET(_target "${ARGN}")
    ENDIF()

    FOREACH(_prop ${PROJECT_PROPERTIES})
	IF(NOT DEFINED ${proj}_${_prop})
	    SET(${proj}_${_prop} ${${_prop}_DEFAULT})
	ENDIF(NOT DEFINED ${proj}_${_prop})
	# MESSAGE("${proj}_${_prop}=${${proj}_${_prop}}")
    ENDFOREACH(_prop ${PROJECT_PROPERTIES})

    # Project wide zanata.xml (means: no ver info yet)
    SET(_proj_dir_absolute ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj})
    SET(_zanata_xml_path ${_proj_dir_absolute}/zanata.xml)

    ADD_CUSTOM_COMMAND(OUTPUT ${_zanata_xml_path}
	COMMAND scripts/generate_zanata_xml.sh ${_proj_dir_absolute}
	${ZANATA_URL} ${proj}
	DEPENDS ${_proj_dir_absolute}
	COMMENT "   Generate ${_zanata_xml_path}"
	VERBATIM
	)
    ADD_CUSTOM_COMMAND(OUTPUT ${_proj_dir_absolute}
	COMMAND ${CMAKE_COMMAND} -E make_directory ${_proj_dir_absolute}
	DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}
	)

    ADD_CUSTOM_TARGET(prepare_${proj})
    ADD_DEPENDENCIES(prepare_all_projects prepare_${proj})

    FOREACH(_ver ${_projVers})
	# Prepare project: To make project workable with zanata,
	# such as generate zanata.xml, pot, pom.xml and publican
	ADD_CUSTOM_TARGET(prepare_${proj}_${_ver})
	ADD_DEPENDENCIES(prepare_${proj} prepare_${proj}_${_ver})
	SET_LOCAL_VARS("${proj}" "${_ver}" "src")

	IF("${${proj}_PROJECT_TYPE}" STREQUAL "")
	    SET(_projType_opt "")
	ELSE("${${proj}_PROJECT_TYPE}" STREQUAL "")
		SET(_projType_opt -t ${${proj}_PROJECT_TYPE})
	ENDIF("${${proj}_PROJECT_TYPE}" STREQUAL "")

	ADD_CUSTOM_COMMAND(OUTPUT ${_zanata_xml_path}
	    COMMAND scripts/generate_zanata_xml.sh ${_projType_opt}
	    -v ${_ver}  -l "${LANGS}"
	    -z ${_zanata_xml_path} ${_proj_ver_base_dir_absolute} ${ZANATA_URL} ${proj}
	    DEPENDS ${_proj_ver_dir_absolute}
	    COMMENT "   Generate ${_zanata_xml_path}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(generate_zanata_xml_${proj}_${_ver}
	    DEPENDS ${_zanata_xml_path}
	    )

	ADD_DEPENDENCIES(prepare_${proj}_${_ver}
	    preprocess_publican_${proj}_${_ver}
	    )


	IF(NOT "${${proj}_POT_GEN_CMD}" STREQUAL "")
	    ADD_CUSTOM_TARGET(generate_pot_${proj}_${_ver}
		COMMAND eval "${${proj}_POT_GEN_CMD}"
		WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
		COMMENT "   Generate pot for ${proj} ${_ver}"
		VERBATIM
		)
	    ADD_DEPENDENCIES(prepare_${proj}_${_ver} generate_pot_${proj}_${_ver})
	ENDIF(NOT "${${proj}_POT_GEN_CMD}" STREQUAL "")


	ADD_CUSTOM_COMMAND(OUTPUT ${_proj_ver_publican_cfg_absolute}.striped
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/preprocess_publican.sh "${LANGS}"
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    DEPENDS ${_zanata_xml_path}
	    COMMENT "   Strip missing publican refs for project ${proj}/${_ver} "
	    VERBATIM
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${_proj_ver_dir_absolute}
	    COMMAND perl scripts/get_project.pl ${SAMPLE_PROJ_DIR_ABSOLUTE} ${proj}
	    ${${proj}_REPO_TYPE} ${_ver} ${${proj}_URL_${_ver}}
	    DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}
	    COMMENT "   Get sources of ${proj} ${_ver}:${${proj}_NAME} from ${${proj}_URL_${_ver}}"
	    VERBATIM
	    )

	IF(NOT TARGET preprocess_publican_${proj}_${_ver})
	    ADD_CUSTOM_TARGET(preprocess_publican_${proj}_${_ver}
		DEPENDS ${_proj_ver_publican_cfg_absolute}.striped
	    	)
	    ADD_DEPENDENCIES(prepare_${proj}_${_ver} preprocess_publican_${proj}_${_ver})
	ENDIF(NOT TARGET preprocess_publican_${proj}_${_ver})
    ENDFOREACH(_ver ${_projVers})

ENDMACRO(ADD_SOURCE_PROJECT proj)

#===================================================================
# Maven targets
#
CONFIGURE_FILE(pom.xml.in pom.xml @ONLY)

SET(ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS
    -Dzanata.url=${ZANATA_URL}
    -Dzanata.userConfig=${CMAKE_SOURCE_DIR}/zanata.ini
    -Dzanata.username=${ADMIN_USER}
    -Dzanata.key=${ADMIN_KEY}
    )

MACRO(ADD_MVN_CLIENT_TARGETS proj )
    SET(_projVers "${${proj}_VERS}")
    SET(ZANATA_MVN_COMMON_OPTS -e)

    ADD_CUSTOM_TARGET(zanata_putproject_mvn_${proj}
	COMMAND ${ZANATA_MVN_CMD}
	${ZANATA_MVN_COMMON_OPTS}
	${MVN_GOAL_PREFIX}:putproject
	${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	-Dzanata.projectSlug=${proj}
	-Dzanata.projectName=${${proj}_NAME}
	-Dzanata.projectDesc=${${proj}_DESC}
	DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/zanata.xml
	COMMENT "  [Mvn] Creating proj: proj ${proj}:${${proj}_NAME} in ${ZANATA_URL}"
	VERBATIM
	)

    FOREACH(_ver ${_projVers})
	#MESSAGE("[mvn] proj=${proj} ver=${_ver}")
	ADD_CUSTOM_TARGET(rest_test_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_mvn rest_test_mvn_${proj}_${_ver})
	SET_LOCAL_VARS(${proj} "${_ver}" "mvn")

	SET(_proj_ver_pom_xml_absolute
	    ${_proj_ver_base_dir_absolute}/pom.xml)

	SET(ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS "")
	IF(${proj}_ZANATA_XML)
	    LIST(APPEND ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS "-Dzanata.projectConfig=${_zanata_xml_path}")
	ENDIF(${proj}_ZANATA_XML)

	IF(_projType STREQUAL "xliff")
		SET(zanata_includes "-Dzanata.includes=**/StringResource_en_US.xml")
	ELSE(_projType STREQUAL "xliff")
		SET(zanata_includes "")
	ENDIF(_projType STREQUAL "xliff")

	IF(${proj}_PROJ_TYPE)
	    LIST(APPEND ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS "-Dzanata.projectType=${_projType}")
	ENDIF(${proj}_PROJ_TYPE)

	SET(ZANATA_MVN_PUSH_OPTS "")
	IF("${${proj}_SRC_DIR}" STREQUAL "")
	    IF("${_projType}" STREQUAL "podir")
		SET(SRC_DIR "pot")
		LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.srcDir=${SRC_DIR}")
	    ELSE("${_projType}" STREQUAL "podir")
		SET(SRC_DIR ".")
	    ENDIF("${_projType}" STREQUAL "podir")
	ELSE()
	    SET(SRC_DIR "${${proj}_SRC_DIR}")
	    LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.srcDir=${SRC_DIR}")
	ENDIF()

	IF("${${proj}_TRANS_DIR}" STREQUAL "")
	    SET(TRANS_DIR ".")
	ELSE()
	    SET(TRANS_DIR "${${proj}_TRANS_DIR}")
	    LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.transDir=${TRANS_DIR}")
	ENDIF()


	# Generate pom.xml
	CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/pom.xml.in ${_proj_ver_pom_xml_absolute} @ONLY)

	# Put version
	ADD_CUSTOM_TARGET(zanata_putversion_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD}
	    ${ZANATA_MVN_COMMON_OPTS}
	    ${MVN_GOAL_PREFIX}:putversion
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dzanata.versionSlug=${_ver}
	    -Dzanata.versionProject=${proj}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "  [Mvn] Creating version: proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_putversion_mvn_${proj}_${_ver} zanata_putproject_mvn_${proj}
	    prepare_${proj}_${_ver})

	# Generic push
	ADD_CUSTOM_TARGET(zanata_push_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD} -B
	    ${ZANATA_MVN_COMMON_OPTS}
	    ${MVN_GOAL_PREFIX}:push
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_MVN_PUSH_OPTS}
	    ${zanata_includes}
	    -Dzanata.pushTrans
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "  [Mvn] Pushing pot and po for proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_push_mvn_${proj}_${_ver} zanata_putversion_mvn_${proj}_${_ver})

	SET(ZANATA_MVN_PULL_OPTS "")
	LIST(APPEND ZANATA_MVN_PULL_OPTS "-Dzanata.srcDir=${_pull_dest_dir_absolute}/${SRC_DIR}")
	LIST(APPEND ZANATA_MVN_PULL_OPTS "-Dzanata.transDir=${_pull_dest_dir_absolute}/${TRANS_DIR}")

	# Generic pull
	ADD_CUSTOM_TARGET(zanata_pull_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD}
	    ${ZANATA_MVN_COMMON_OPTS}
	    -B ${MVN_GOAL_PREFIX}:pull
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_MVN_PULL_OPTS}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    DEPENDS ${_pull_dest_dir_absolute}
	    COMMENT "  [Mvn] Pulling pot and po for proj ${proj} ver ${_ver} from  ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_pull_mvn_${proj}_${_ver}
	    zanata_push_mvn_${proj}_${_ver}  zanata_putversion_mvn_${proj}_${_ver})

	# Verify the pulled
	REST_VERIFY(${proj} ${_ver} ${_projType} "mvn" "${_proj_ver_base_dir_absolute}" "${_pull_dest_dir_absolute}")

	ADD_CUSTOM_COMMAND(OUTPUT ${_pull_dest_dir_absolute}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_pull_dest_dir_absolute}
	        )
    ENDFOREACH(_ver ${_projVers})
ENDMACRO(ADD_MVN_CLIENT_TARGETS proj)

#===================================================================
# Python targets
#
SET(ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS --username ${ADMIN_USER} --apikey ${ADMIN_KEY}
    --url ${ZANATA_URL} --user-config ${CMAKE_SOURCE_DIR}/zanata.ini)

MACRO(ADD_PY_CLIENT_TARGETS proj )
    SET(_projVers "${${proj}_VERS}")

    ADD_CUSTOM_TARGET(zanata_project_create_py_${proj}
	COMMAND ${ZANATA_PY_CMD} project create ${proj}
	${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	--project-name=${${proj}_NAME}
	--project-desc=${${proj}_DESC}
	DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/zanata.xml
	COMMENT "  [Py] Creating proj: proj ${proj}:${${proj}_NAME} in ${ZANATA_URL}"
	WORKING_DIRECTORY ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}
	VERBATIM
	)

    FOREACH(_ver ${_projVers})
	#MESSAGE("[py] proj=${proj} ver=${_ver}")
	ADD_CUSTOM_TARGET(rest_test_py_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_py rest_test_py_${proj}_${_ver})
	SET_LOCAL_VARS("${proj}" "${_ver}" "py")

	SET(ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS
	    --project-id=${proj}
	    --project-version=${_ver}
	    )

	SET(ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS "")
	IF(${proj}_ZANATA_XML)
	    LIST(APPEND ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS "--project-config=${_zanata_xml_path}")
	ENDIF(${proj}_ZANATA_XML)

	IF(${proj}_PROJ_TYPE)
	    LIST(APPEND ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS "--project-type=${_projType}")
	ENDIF(${proj}_PROJ_TYPE)

	SET(ZANATA_PY_PUSH_OPTS "")
	IF("${${proj}_SRC_DIR}" STREQUAL "")
	    IF("${_projType}" STREQUAL "podir")
		SET(SRC_DIR "pot")
		LIST(APPEND ZANATA_PY_PUSH_OPTS "--srcdir=${SRC_DIR}")
	    ELSE("${_projType}" STREQUAL "podir")
		SET(SRC_DIR ".")
	    ENDIF("${_projType}" STREQUAL "podir")
	ELSE()
	    SET(SRC_DIR "${${proj}_SRC_DIR}")
	    LIST(APPEND ZANATA_PY_PUSH_OPTS "--srcdir=${SRC_DIR}")
	ENDIF()

	IF("${${proj}_TRANS_DIR}" STREQUAL "")
	    SET(TRANS_DIR ".")
	ELSE()
	    SET(TRANS_DIR "${${proj}_TRANS_DIR}")
	    LIST(APPEND ZANATA_PY_PUSH_OPTS "--transdir=${TRANS_DIR}")
	ENDIF()

	# Put version
	ADD_CUSTOM_TARGET(zanata_version_create_py_${proj}_${_ver}
	    COMMAND  ${ZANATA_PY_CMD} version create ${_ver}
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "  [Py] Creating version: proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_version_create_py_${proj}_${_ver}
	    zanata_project_create_py_${proj} prepare_${proj}_${_ver})

	# Generic push
	ADD_CUSTOM_TARGET(zanata_push_py_${proj}_${_ver}
	    COMMAND yes | ${ZANATA_PY_CMD} push
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_PY_PUSH_OPTS}
	    --push-trans
	    DEPENDS ${_zanata_xml_path}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "  [Py] Uploading pot and po for proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_push_py_${proj}_${_ver} zanata_version_create_py_${proj}_${_ver})

	SET(ZANATA_PY_PULL_OPTS "")
	LIST(APPEND ZANATA_PY_PULL_OPTS "--srcdir=${_pull_dest_dir_absolute}/${SRC_DIR}")
	LIST(APPEND ZANATA_PY_PULL_OPTS "--transdir=${_pull_dest_dir_absolute}/${TRANS_DIR}")

	# Generic pull
	ADD_CUSTOM_TARGET(zanata_pull_py_${proj}_${_ver}
	    COMMAND ${ZANATA_PY_CMD} pull
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_PY_PULL_OPTS}
	    DEPENDS ${_pull_dest_dir_absolute}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "  [Py] Pulling pot and po for proj ${proj} ver ${_ver} from  ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_pull_py_${proj}_${_ver}
	    zanata_push_py_${proj}_${_ver}  zanata_version_create_py_${proj}_${_ver})

	# Verify the pulled
	REST_VERIFY(${proj} ${_ver} ${_projType} "py" "${_proj_ver_base_dir_absolute}" "${_pull_dest_dir_absolute}")

	ADD_CUSTOM_COMMAND(OUTPUT ${_pull_dest_dir_absolute}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_pull_dest_dir_absolute}
	    )
    ENDFOREACH(_ver ${_projVers})
ENDMACRO(ADD_PY_CLIENT_TARGETS proj)

#===================================================================
# REST test targets
#

MACRO(GENERATE_REST_TEST_CLIENT_TARGETS clientId)
    STRING(TOUPPER "${clientId}" _clientDisplay)
    IF("${ZANATA_${_clientDisplay}_CMD}" STREQUAL "ZANATA_${_clientDisplay}_CMD-NOTFOUND")
	MESSAGE("zanata ${clientId} is not installed! ${clientId} tests disabled.")
    ELSE("${ZANATA_${_clientDisplay}_CMD}" STREQUAL "ZANATA_${_clientDisplay}_CMD-NOTFOUND")
	MESSAGE("[${_clientDisplay}] client is ${ZANATA_${_clientDisplay}_CMD}")
	ADD_CUSTOM_TARGET(rest_test_${clientId}
	    COMMENT "[${_clientDisplay}] REST API tests."
	    )

	FOREACH(_proj ${${_clientDisplay}_PROJECTS})
	    IF(NOT TARGET prepare_${_proj})
		ADD_SOURCE_PROJECT(${_proj})
	    ENDIF(NOT TARGET prepare_${_proj})
	    IF("${clientId}" STREQUAL "py")
		ADD_PY_CLIENT_TARGETS(${_proj})
	    ELSE("${clientId}" STREQUAL "py")
		# MVN client
		ADD_MVN_CLIENT_TARGETS(${_proj})
	    ENDIF("${clientId}" STREQUAL "py")
	ENDFOREACH(_proj ${${_clientDisplay}_PROJECTS})
    ENDIF("${ZANATA_${_clientDisplay}_CMD}" STREQUAL "ZANATA_${_clientDisplay}_CMD-NOTFOUND")
ENDMACRO(GENERATE_REST_TEST_CLIENT_TARGETS clientId)

GENERATE_REST_TEST_CLIENT_TARGETS(mvn)

GENERATE_REST_TEST_CLIENT_TARGETS(py)

#===================================================================
# Targets to process only projects that have selenium tests associated.
#
ADD_CUSTOM_TARGET(selenium_projects
    COMMENT "   Preparing projects for selenium tests"
    )

ADD_CUSTOM_TARGET(prepare_selenium_projects
    COMMENT "   Generate zanata.xml for selenium testing projects"
    )

ADD_DEPENDENCIES(prepare_selenium_projects
    prepare_ReleaseNotes_f13 prepare_SecurityGuide_f13)

ADD_DEPENDENCIES(selenium_projects zanata_push_mvn_ReleaseNotes_f13
    zanata_push_mvn_SecurityGuide_f13)

