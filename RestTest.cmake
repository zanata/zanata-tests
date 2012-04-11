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
REQUIRE_CMD(ZANATA_ZANATA_XML_MAKE_CMD zanata_zanata_xml_make)
REQUIRE_CMD(ZANATA_POM_XML_MAKE_CMD zanata_pom_xml_make)

SET(ZANATAC_CMD "${SCRIPT_DIR}/zanatac" "--yes" "--show")
SET(ZANATA_MVN_CMD ${ZANATAC_CMD})
SET(ZANATA_PY_CMD  ${ZANATAC_CMD} --client py)

ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR_ABSOLUTE}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${SAMPLE_PROJ_DIR_ABSOLUTE}
    )

ADD_CUSTOM_TARGET(prepare
    COMMENT "Prepare all projects"
    )

#===================================================================
# Macros
#
MACRO(REST_VERIFY proj ver projType client baseDir pullDest srcDir transDir)
    # Note that verifing properties projects is not implemented yet
    # MESSAGE("proj=${proj} ver=${ver} projType=|${projType}| client=${client}")
    IF("${projType}" STREQUAL "podir")
	ADD_CUSTOM_TARGET(rest_verify_${client}_${proj}_${ver}
	    COMMAND scripts/compare_translation_dir.sh
	    ${baseDir}/${srcDir}
	    ${baseDir}/${transDir} ${pullDest} "${LANGS}"
	    COMMENT "[${client}][${proj}-${ver}] Verifying the pulled contents with original translation"
	    VERBATIM
	    )
    ELSEIF("${projType}" STREQUAL "gettext")
	ADD_CUSTOM_TARGET(rest_verify_${client}_${proj}_${ver}
		COMMAND scripts/compare_translation_dir.sh -g
		${baseDir}/${${proj}_POT}
		${baseDir}/${transDir} ${pullDest} "${LANGS}"
		COMMENT "[${client}][${proj}-${ver}] Verifying the pulled contents with original translation"
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
ENDMACRO(REST_VERIFY proj ver projType client baseDir pullDest srcDir transDir)

MACRO(SET_LOCAL_VARS proj ver client)
    SET(_proj_ver_dir_absolute
	"${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/${ver}")
    SET(_proj_ver_base_dir_absolute
	"${_proj_ver_dir_absolute}/${${proj}_BASE_DIR}")
    SET(_proj_ver_publican_cfg_absolute
	"${_proj_ver_base_dir_absolute}/publican.cfg")
    SET(_proj_ver_publican_cfg_striped_absolute
	"${_proj_ver_publican_cfg_absolute}.striped")

    IF(NOT "${client}" STREQUAL "src")
	SET(_pull_dest_dir_absolute ${PULL_DEST_DIR_ABSOLUTE}/${client}/${proj}/${ver})
    ENDIF(NOT "${client}" STREQUAL "src")

    IF("${${proj}_ZANATA_XML}" STREQUAL "")
	SET(_zanata_xml_path ${_proj_ver_base_dir_absolute}/zanata.xml)
    ELSE("${${proj}_ZANATA_XML}" STREQUAL "")
	SET(_zanata_xml_path ${_proj_ver_base_dir_absolute}/${${proj}_ZANATA_XML})
    ENDIF("${${proj}_ZANATA_XML}" STREQUAL "")

    IF("${${proj}_PROJECT_TYPE}" STREQUAL "")
        SET(_proj_type ${PROJECT_TYPE_DEFAULT})
    ELSE("${${proj}_PROJECT_TYPE}" STREQUAL "")
        SET(_proj_type ${${proj}_PROJECT_TYPE})
    ENDIF("${${proj}_PROJECT_TYPE}" STREQUAL "")

    IF("${${proj}_SRC_DIR}" STREQUAL "")
	IF("${_proj_type}" STREQUAL "podir")
	    SET(_proj_src_dir "pot")
	ELSE("${_proj_type}" STREQUAL "podir")
	    SET(_proj_src_dir ".")
	ENDIF("${_proj_type}" STREQUAL "podir")
    ELSE()
	SET(_proj_src_dir "${${proj}_SRC_DIR}")
    ENDIF()

    IF("${${proj}_TRANS_DIR}" STREQUAL "")
	SET(_proj_trans_dir ".")
    ELSE()
	SET(_proj_trans_dir "${${proj}_TRANS_DIR}")
    ENDIF()

    IF("${${proj}_REPO_TYPE}" STREQUAL "")
	SET(${proj}_REPO_TYPE "git")
    ENDIF("${${proj}_REPO_TYPE}" STREQUAL "")

    SET(_proj_ver_dir_scm "${_proj_ver_dir_absolute}/.${${proj}_REPO_TYPE}")
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
    SET(_proj_base_zanata_xml_path ${_proj_dir_absolute}/zanata.xml)

    ADD_CUSTOM_COMMAND(OUTPUT ${_proj_dir_absolute}
	COMMAND ${CMAKE_COMMAND} -E make_directory ${_proj_dir_absolute}
	DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}
	)

    SET(BASE_ZANATA_XML_MAKE_OPTS "--projectType" "${${proj}_PROJECT_TYPE}")

    ADD_CUSTOM_COMMAND(OUTPUT ${_proj_base_zanata_xml_path}
	COMMAND ${ZANATA_ZANATA_XML_MAKE_CMD} ${BASE_ZANATA_XML_MAKE_OPTS} ${ZANATA_URL} ${proj}
	DEPENDS ${_proj_dir_absolute}
	COMMENT "[${proj}] make ${_proj_base_zanata_xml_path}"
	WORKING_DIRECTORY ${_proj_dir_absolute}
	VERBATIM
	)

    ADD_CUSTOM_TARGET(prepare_${proj})
    ADD_DEPENDENCIES(prepare prepare_${proj})

    FOREACH(_ver ${_projVers})
	# Prepare project: To make project workable with zanata,
	# such as generate zanata.xml, pot, pom.xml and publican
	SET_LOCAL_VARS("${proj}" "${_ver}" "src")

	ADD_CUSTOM_COMMAND(OUTPUT ${_proj_ver_dir_scm}
	    COMMAND perl scripts/get_project.pl ${SAMPLE_PROJ_DIR_ABSOLUTE} ${proj}
	    ${${proj}_REPO_TYPE} ${_ver} ${${proj}_URL_${_ver}}
	    DEPENDS ${_proj_base_zanata_xml_path}
	    COMMENT "[${proj}-${_ver}] Download source from ${${proj}_URL_${_ver}}"
	    VERBATIM
	    )

	ADD_CUSTOM_COMMAND(OUTPUT "${_proj_ver_publican_cfg_striped_absolute}" "${_proj_ver_base_dir_absolute}/${_proj_src_dir}" "${_proj_ver_base_dir_absolute}/${_proj_trans_dir}"
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/generate_trans_template.sh
	    "${LANGS}" "${${proj}_POST_DOWNLOAD_CMD}"
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    DEPENDS "${_proj_ver_dir_scm}"
	    COMMENT "[${proj}-${_ver}] Translation template files (.pot and .po)"
	    VERBATIM
	    )

	SET(ZANATA_XML_MAKE_OPTS ${BASE_ZANATA_XML_MAKE_OPTS})

	IF(NOT "${${proj}_ZANATA_XML}" STREQUAL "")
	    LIST(APPEND ZANATA_XML_MAKE_OPTS "--zanataXml" "${${proj}_ZANATA_XML}")
	ENDIF(NOT "${${proj}_ZANATA_XML}" STREQUAL "")

	IF(NOT "${${proj}_SRC_DIR}" STREQUAL "")
	    LIST(APPEND ZANATA_XML_MAKE_OPTS "--srcDir" "${${proj}_SRC_DIR}")
	ENDIF(NOT "${${proj}_SRC_DIR}" STREQUAL "")

	IF(NOT "${${proj}_TRANS_DIR}" STREQUAL "")
	    LIST(APPEND ZANATA_XML_MAKE_OPTS "--transDir" "${${proj}_TRANS_DIR}")
	ENDIF(NOT "${${proj}_TRANS_DIR}" STREQUAL "")

	ADD_CUSTOM_COMMAND(OUTPUT ${_zanata_xml_path}
	    COMMAND ${ZANATA_ZANATA_XML_MAKE_CMD} ${ZANATA_XML_MAKE_OPTS} ${ZANATA_URL} ${proj} ${_ver}
	    DEPENDS "${_proj_ver_publican_cfg_striped_absolute}"
	    COMMENT "[${proj}-${_ver}] make ${_zanata_xml_path}"
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(prepare_${proj}_${_ver}
	    DEPENDS ${_zanata_xml_path}
	    COMMENT "[${proj}-${_ver}] Preparing zanata related files"
	    )
	ADD_DEPENDENCIES(prepare_${proj} prepare_${proj}_${_ver})

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

#===================================================================
# Generate pom.xml
#
MACRO(GENERATE_POM_XML proj ver)
    SET(_pomXml "${_proj_ver_base_dir_absolute}/pom.xml")
    #MESSAGE("_proj_ver_dir_scm=${_proj_ver_dir_scm}")
    ADD_CUSTOM_COMMAND(OUTPUT "${_pomXml}.stamp"
	COMMAND scripts/pomXml_generate.pl -p -s "${${proj}_REPO_TYPE}" "${_pomXml}" "${proj}"
	COMMENT "Generating ${_pomXml} for ${proj}"
	DEPENDS "${_proj_ver_dir_scm}"
	VERBATIM
	)
    SET(_clean_pom_xml_cmd "scripts/pomXml_generate.pl -c -s ${${proj}_REPO_TYPE} ${_pomXml} ${proj}")
    SET(_stamp_list "${_pomXml}.stamp")


    # Generate additional pom.xml
    FOREACH(_pomXmlProf ${${proj}_POM_XML_LIST})
	SET(_pomXml "${_proj_ver_dir_absolute}/${${_pomXmlProf}}")
	#    MESSAGE("_pomXml=${_pomXml}")
	ADD_CUSTOM_COMMAND(OUTPUT "${_pomXml}.stamp"
	    COMMAND scripts/pomXml_generate.pl -s "${${proj}_REPO_TYPE}" "${_pomXml}" "${_pomXmlProf}"
	    COMMENT "Generating ${_pomXml} for ${_pomXmlProf}"
	    DEPENDS "${_proj_ver_dir_scm}"
	    VERBATIM
	    )
	LIST(APPEND _clean_pom_xml_cmd "scripts/pomXml_generate.pl -c -s ${${proj}_REPO_TYPE} ${_pomXml} ${proj}")
	LIST(APPEND _stamp_list "${_pomXml}.stamp")
    ENDFOREACH(_pomXmlProf ${${proj}_POM_XML_LIST})


    ADD_CUSTOM_TARGET(generate_pom_xml_${proj}_${ver}
	DEPENDS ${_stamp_list}
	)
    ADD_DEPENDENCIES(generate_pom_xml generate_pom_xml_${proj}_${ver})

    ADD_CUSTOM_TARGET(clean_pom_xml_${proj}_${ver}
	COMMAND eval "${_clean_pom_xml_cmd}"
	COMMENT "Clean ${_pomXml} for ${proj}"
	VERBATIM
	)
    ADD_DEPENDENCIES(clean_pom_xml clean_pom_xml_${proj}_${ver})
ENDMACRO(GENERATE_POM_XML stampList scm pomXml proj ver varPrefix)

#===================================================================
# Add MVN client
#
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
	COMMENT "[Mvn][${proj}] putproject :${${proj}_NAME} in ${ZANATA_URL}"
	VERBATIM
	)

    IF(COPY_TRANS EQUAL 0)
	SET(_copyTransOpts "-Dzanata.copyTrans=false")
    ELSEIF(COPY_TRANS EQUAL 1)
	SET(_copyTransOpts "-Dzanata.copyTrans=true")
    ELSE(COPY_TRANS EQUAL 0)
	SET(_copyTransOpts "")
    ENDIF(COPY_TRANS EQUAL 0)

    IF(NOT TARGET generate_pom_xml)
	ADD_CUSTOM_TARGET(generate_pom_xml)
    ENDIF(NOT TARGET generate_pom_xml)

    IF(NOT TARGET clean_pom_xml)
	ADD_CUSTOM_TARGET(clean_pom_xml
	    COMMENT "Clean all pom.xml"
	    )
    ENDIF(NOT TARGET clean_pom_xml)

    FOREACH(_ver ${_projVers})
	#MESSAGE("[mvn] proj=${proj} ver=${_ver}")
	SET_LOCAL_VARS(${proj} "${_ver}" "mvn")
	# Generate pom.xml
	GENERATE_POM_XML("${proj}" "${_ver}")

	# Other options
	SET(ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS "")
	IF(${proj}_ZANATA_XML)
	    LIST(APPEND ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS "-Dzanata.projectConfig=${_zanata_xml_path}")
	ENDIF(${proj}_ZANATA_XML)

	IF(_proj_type STREQUAL "xliff")
		SET(zanata_includes "-Dzanata.includes=**/StringResource_en_US.xml")
	ELSE(_proj_type STREQUAL "xliff")
		SET(zanata_includes "")
	ENDIF(_proj_type STREQUAL "xliff")

	IF(${proj}_PROJ_TYPE)
	    LIST(APPEND ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS "-Dzanata.projectType=${_proj_type}")
	ENDIF(${proj}_PROJ_TYPE)

	SET(ZANATA_MVN_PUSH_OPTS "${_copyTransOpts}" "-Dzanata.pushTrans")

	SET(_file_depend_list "")
	# Only show put as parameter if it is necessary or explicitly defined.
	IF(NOT "${_proj_src_dir}" STREQUAL ".")
	    LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.srcDir=${_proj_src_dir}")
	    LIST(APPEND _file_depend_list "${_proj_ver_base_dir_absolute}/${_proj_src_dir}")
	ELSEIF(NOT "${${proj}_SRC_DIR}" STREQUAL "")
	    LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.srcDir=${${proj}_SRC_DIR}")
	ENDIF()

	IF(NOT "${_proj_trans_dir}" STREQUAL ".")
	    LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.transDir=${_proj_trans_dir}")
	    LIST(APPEND _file_depend_list "${_proj_ver_base_dir_absolute}/${_proj_trans_dir}")
	ELSEIF(NOT "${${proj}_TRANS_DIR}" STREQUAL "")
	    LIST(APPEND ZANATA_MVN_PUSH_OPTS "-Dzanata.transDir=${${proj}_TRANS_DIR}")
	ENDIF()

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
	    DEPENDS  ${_zanata_xml_path} ${_stamp_list}
	    COMMENT "[Mvn][${proj}-${_ver}] putversion to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_putversion_mvn_${proj}_${_ver}
	    zanata_putproject_mvn_${proj})

	# Generic push
	ADD_CUSTOM_TARGET(zanata_push_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD} -B
	    ${ZANATA_MVN_COMMON_OPTS}
	    ${MVN_GOAL_PREFIX}:push
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_MVN_PUSH_OPTS}
	    ${zanata_includes}
	    DEPENDS  ${_zanata_xml_path} ${_stamp_list} ${_file_depend_list}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "[Mvn][${proj}-${_ver}] push with options: ${ZANATA_MVN_PUSH_OPTS}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_push_mvn_${proj}_${_ver} zanata_putversion_mvn_${proj}_${_ver})

	SET(ZANATA_MVN_PULL_OPTS "")
	LIST(APPEND ZANATA_MVN_PULL_OPTS "-Dzanata.srcDir=${_pull_dest_dir_absolute}/${_proj_src_dir}")
	LIST(APPEND ZANATA_MVN_PULL_OPTS "-Dzanata.transDir=${_pull_dest_dir_absolute}/${_proj_trans_dir}")

	# Generic pull
	ADD_CUSTOM_TARGET(zanata_pull_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD}
	    ${ZANATA_MVN_COMMON_OPTS}
	    -B ${MVN_GOAL_PREFIX}:pull
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_MVN_PULL_OPTS}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    DEPENDS  ${_zanata_xml_path} ${_stamp_list} ${_pull_dest_dir_absolute}
	    COMMENT "[Mvn][${proj}-${_ver}] pull with options: ${ZANATA_MVN_PULL_OPTS}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_pull_mvn_${proj}_${_ver} zanata_push_mvn_${proj}_${_ver})

	ADD_CUSTOM_TARGET(rest_test_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_mvn rest_test_mvn_${proj}_${_ver})
	# Verify the pulled
	REST_VERIFY(${proj} ${_ver} ${_proj_type} "mvn" "${_proj_ver_base_dir_absolute}" "${_pull_dest_dir_absolute}"
	    "${_proj_src_dir}" "${_proj_trans_dir}")

	ADD_CUSTOM_COMMAND(OUTPUT ${_pull_dest_dir_absolute}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_pull_dest_dir_absolute}
	    COMMENT "[Mvn] mkdir ${_pull_dest_dir_absolute}"
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
	COMMENT "[Py][${proj}] create project :${${proj}_NAME} in ${ZANATA_URL}"
	WORKING_DIRECTORY ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}
	VERBATIM
	)

    IF(COPY_TRANS EQUAL 0)
	SET(_copyTransOpts "--no-copytrans")
    ELSE(COPY_TRANS EQUAL 1)
	SET(_copyTransOpts "")
    ENDIF(COPY_TRANS EQUAL 0)

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
	    LIST(APPEND ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS "--project-type=${_proj_type}")
	ENDIF(${proj}_PROJ_TYPE)

	SET(ZANATA_PY_PUSH_OPTS "${_copyTransOpts}" "--push-trans" )

	SET(_file_depend_list "")
	# Only show put as parameter if it is necessary or explicitly defined.
	IF(NOT "${_proj_src_dir}" STREQUAL ".")
	    LIST(APPEND ZANATA_PY_PUSH_OPTS "--srcdir=${_proj_src_dir}")
	    LIST(APPEND _file_depend_list "${_proj_ver_base_dir_absolute}/${_proj_src_dir}")
	ELSEIF(NOT "${${proj}_SRC_DIR}" STREQUAL "")
	    LIST(APPEND ZANATA_PY_PUSH_OPTS "--srcdir=${${proj}_SRC_DIR}")
	ENDIF()

	IF(NOT "${_proj_trans_dir}" STREQUAL ".")
	    LIST(APPEND ZANATA_PY_PUSH_OPTS "--transdir=${_proj_trans_dir}")
	    LIST(APPEND _file_depend_list "${_proj_ver_base_dir_absolute}/${_proj_trans_dir}")
	ELSEIF(NOT "${${proj}_TRANS_DIR}" STREQUAL "")
	    LIST(APPEND ZANATA_PY_PUSH_OPTS "--transdir=${${proj}_TRANS_DIR}")
	ENDIF()

	# Put version
	ADD_CUSTOM_TARGET(zanata_version_create_py_${proj}_${_ver}
	    COMMAND  ${ZANATA_PY_CMD} version create ${_ver}
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    DEPENDS  ${_zanata_xml_path}
	    COMMENT "[Py][${proj}-${_ver}] create version to ${ZANATA_URL}"
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
	    ${_copyTransOpts}
	    DEPENDS ${_zanata_xml_path}  ${_file_depend_list}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "[Py][${proj}-${_ver}] push with options: ${ZANATA_PY_PUSH_OPTS}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_push_py_${proj}_${_ver} zanata_version_create_py_${proj}_${_ver})

	SET(ZANATA_PY_PULL_OPTS "")
	LIST(APPEND ZANATA_PY_PULL_OPTS "--srcdir=${_pull_dest_dir_absolute}/${_proj_src_dir}")
	LIST(APPEND ZANATA_PY_PULL_OPTS "--transdir=${_pull_dest_dir_absolute}/${_proj_trans_dir}")

	# Generic pull
	ADD_CUSTOM_TARGET(zanata_pull_py_${proj}_${_ver}
	    COMMAND ${ZANATA_PY_CMD} pull
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    ${ZANATA_PY_PULL_OPTS}
	    DEPENDS ${_pull_dest_dir_absolute}
	    WORKING_DIRECTORY ${_proj_ver_base_dir_absolute}
	    COMMENT "[Py][${proj}-${_ver}] pull with options: ${ZANATA_PY_PULL_OPTS}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_pull_py_${proj}_${_ver} zanata_push_py_${proj}_${_ver})

	# Verify the pulled
	REST_VERIFY(${proj} ${_ver} ${_proj_type} "py" "${_proj_ver_base_dir_absolute}" "${_pull_dest_dir_absolute}"
	    "${_proj_src_dir}" "${_proj_trans_dir}")

	ADD_CUSTOM_COMMAND(OUTPUT ${_pull_dest_dir_absolute}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_pull_dest_dir_absolute}
	    COMMENT "[Py] mkdir ${_pull_dest_dir_absolute}"
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

