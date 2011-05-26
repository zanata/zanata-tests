cmake_minimum_required(VERSION 2.4)
####################################################################
# Init Definition
####################################################################
PROJECT(zanata-tests NONE)
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
MESSAGE("CMake version=${CMAKE_VERSION}")

SET(ENV{LC_ALL} "C")

SET(TEST_CFG "test.cfg")
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR})
INCLUDE(ManageVariable)

####################################################################
# Project specific definition
####################################################################
SET(PROJECT_DESCRIPTION "Test system for zanata.openl10n.net")

####################################################################
# Macros
####################################################################

# REAL_PATH(absolutePathToBeReturn path)

MACRO(REAL_PATH var path)
    IF (${path} MATCHES "^/")
	SET(${var} "${path}")
    ELSE(${path} MATCHES "^/")
	SET(${var} "${CMAKE_SOURCE_DIR}/${path}")
    ENDIF(${path} MATCHES "^/")
ENDMACRO(REAL_PATH var path)


####################################################################
# Settings
####################################################################
### Override with environment variables
SET(OVERRIDABLE_VARS  "ZANATA_URL" "BROWSERS_TO_TEST" "SELENIUM_SERVER_PORT"
    "SAMPLE_PROJ_DIR" "PULL_DEST_DIR" "ZANATA_PROFILE" "MVN_CLIENT_VER"
    "ZANATA_PY_PATH")
FOREACH(_envVar  ${OVERRIDABLE_VARS})
    IF(NOT "$ENV{${_envVar}}" STREQUAL "")
	SET(${_envVar} "$ENV{${_envVar}}")
    ENDIF()
ENDFOREACH()

SETTING_FILE_GET_ALL_VARIABLES("${TEST_CFG}" NOREPLACE UNQUOTED NOESCAPE_SEMICOLON)

# Assign PROFILE
MESSAGE("ZANATA_PROFILE=${ZANATA_PROFILE}")
SET(PROFILE_VARIABLES SERVER_BASE SERVER_PATH ADMIN_USER ADMIN_KEY TEST_ROLES KERBEROS
    CONFIG_LANG_ADD_NEW_LANG_ID_PREFIX CONFIG_SERVER_ID_PREFIX CONFIG_LANG_ID_PREFIX
    AUTH_METHOD LOGIN_FIELD_ID PASSWORD_FIELD_ID)
FOREACH(_var ${PROFILE_VARIABLES})
    IF(DEFINED ${ZANATA_PROFILE}_${_var})
	SET(${_var} "${${ZANATA_PROFILE}_${_var}}")
	MESSAGE("Profile ${ZANATA_PROFILE} specific: ${_var}=${${ZANATA_PROFILE}_${_var}}")
    ENDIF(DEFINED ${ZANATA_PROFILE}_${_var})
ENDFOREACH()
SET(ZANATA_URL ${SERVER_BASE}${SERVER_PATH})

### Print variables
FOREACH(_envVar  ${OVERRIDABLE_VARS})
    SET(_envVal "${${_envVar}}")
    MESSAGE("${_envVar}=${_envVal}")
ENDFOREACH()

REAL_PATH(TEST_ROOT_ABSOLUTE "${TEST_ROOT}")
REAL_PATH(PRIVILEGE_TEST_ROOT_ABSOLUTE "${PRIVILEGE_TEST_ROOT}")
REAL_PATH(RESULT_DIR_ABSOLUTE "${RESULT_DIR}")

REAL_PATH(SAMPLE_PROJ_DIR_ABSOLUTE "${SAMPLE_PROJ_DIR}")
REAL_PATH(PULL_DEST_DIR_ABSOLUTE "${PULL_DEST_DIR}")

SET(TEST_ROOT_ABSOLUTE "${CMAKE_SOURCE_DIR}/${TEST_ROOT}")
SET(PRIVILEGE_TEST_ROOT_ABSOLUTE "${CMAKE_SOURCE_DIR}/${PRIVILEGE_TEST_ROOT}")
SET(RESULT_DIR_ABSOLUTE "${CMAKE_SOURCE_DIR}/${RESULT_DIR}")

# Maven
SET(MVN_GOAL_PREFIX "org.zanata:zanata-maven-plugin")


IF(NOT EXISTS ${RESULT_DIR_ABSOLUTE})
    FILE(MAKE_DIRECTORY "${RESULT_DIR_ABSOLUTE}")
ENDIF()


#===================================================================
# Search Paths
SET(MAVEN_REPOSITORY "$ENV{HOME}/.m2/repository/")
SET(MAVEN_SELENIUM_SERVER_PATH "${MAVEN_REPOSITORY}/org/seleniumhq/selenium/server/selenium-server/")
SET(SELENIUM_SEARCH_PATHS ${CMAKE_SOURCE_DIR} ${MAVEN_SELENIUM_SERVER_PATH} /usr/share/java)
MESSAGE("CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}")


#===================================================================
# Macro FIND_FILE_IN_DIRS
MACRO(FIND_FILE_IN_DIRS var pattern searchPaths)
    #MESSAGE("pattern=${pattern} searchPaths=${searchPaths}")
    EXECUTE_PROCESS(COMMAND ${CMAKE_SOURCE_DIR}/scripts/find_file_in_paths.sh ${pattern} "${searchPaths}"
	OUTPUT_VARIABLE _result OUTPUT_STRIP_TRAILING_WHITESPACE)
    MESSAGE("FIND_FILE_IN_DIRS ${var} _result=${_result}")
    SET( ${var} "${_result}")
ENDMACRO()

MACRO(FIND_FILES_IN_DIR var pattern searchPath)
    EXECUTE_PROCESS(COMMAND find ${searchPath} -name "${pattern}" -printf "%p;"
	OUTPUT_VARIABLE _result)
    IF ( _result STREQUAL "")
	SET(${var} "NOTFOUND")
    ELSE()
	SET(${var} ${_result})
    ENDIF()
ENDMACRO()


####################################################################
# Dependencies
####################################################################
FIND_PROGRAM(SELENIUM_SERVER_CMD selenium-server)
IF(${SELENIUM_SERVER_CMD} STREQUAL "SELENIUM_SERVER_CMD-NOTFOUND")
    # find selenium server jar
    FIND_FILE_IN_DIRS(SELENIUM_SERVER_JAR "selenium-server*.jar" "${SELENIUM_SEARCH_PATHS}")
    IF ("${SELENIUM_SERVER_JAR}" STREQUAL "NOTFOUND")
        MESSAGE(FATAL_ERROR "selenium-server not found, install it please.")
    ENDIF()
    SET(SELENIUM_SERVER_CMD java -jar ${SELENIUM_SERVER_JAR})
ENDIF()
MESSAGE("SELENIUM_SERVER_CMD=${SELENIUM_SERVER_CMD}")

### Find the browser binary
FOREACH(_browser ${BROWSERS_TO_TEST})
    FIND_FILE_IN_DIRS(${_browser}_BIN "${${_browser}_BIN_NAME}" "${${_browser}_SEARCH_PATHS}")
    IF("${${_browser}_BIN}" STREQUAL "NOTFOUND")
	MESSAGE(FATAL_ERROR "Cannot find ${_browser} with ${${_browser}_BIN_NAME}, install it please.")
    ELSE()
	MESSAGE("${_browser}_BIN=${${_browser}_BIN}")
    ENDIF()
ENDFOREACH()


####################################################################
# Generate targets
####################################################################

#===================================================================
# Retrieve projects
#

ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR_ABSOLUTE}
    COMMAND mkdir -p ${SAMPLE_PROJ_DIR_ABSOLUTE}
    )

ADD_CUSTOM_TARGET(prepare_all_projects
    COMMENT "Prepare all projects"
    )


ADD_CUSTOM_TARGET(selenium_projects
    COMMENT "   Preparing projects for selenium tests"
    )

ADD_CUSTOM_TARGET(prepare_selenium_projects
    COMMENT "   Generate zanata.xml for selenium testing projects"
    )

ADD_DEPENDENCIES(prepare_selenium_projects
    prepare_ReleaseNotes_f13 prepare_SecurityGuide_f13)

ADD_DEPENDENCIES(selenium_projects zanata_publican_push_mvn_ReleaseNotes_f13
    zanata_publican_push_mvn_SecurityGuide_f13)


#===================================================================
# Publican targets
#
MACRO(ADD_PUBLICAN_PROJECT proj)
    SET(_projVers "${${proj}_VERS}")
    SET(_target "")
    IF(NOT ${ARGN} STREQUAL "")
	SET(_target "${ARGN}")
    ENDIF()

    ADD_CUSTOM_TARGET(prepare_${proj})
    ADD_DEPENDENCIES(prepare_all_projects prepare_${proj})
    SET_TARGET_PROPERTIES(prepare_${proj} PROPERTIES EXISTS TRUE)

    FOREACH(_ver ${_projVers})
	SET(_sample_proj_dir_absolute ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/${_ver})
	SET(_zanata_xml_path ${_sample_proj_dir_absolute}/zanata.xml)

	ADD_CUSTOM_TARGET(generate_zanata_xml_${proj}_${_ver}
	    DEPENDS ${_zanata_xml_path}
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${_zanata_xml_path}
	    COMMAND scripts/generate_zanata_xml.sh ${SAMPLE_PROJ_DIR_ABSOLUTE} ${proj}
	    ${_ver} ${ZANATA_URL} "${LANGS}"
	    DEPENDS ${_sample_proj_dir_absolute}/pot
	    COMMENT "   Generate ${_zanata_xml_path}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(link_pom_xml_${proj}_${_ver}
	    DEPENDS ${_sample_proj_dir_absolute}/pom.xml
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${_sample_proj_dir_absolute}/pom.xml
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/link_pom_xml.sh ${CMAKE_SOURCE_DIR}
	    WORKING_DIRECTORY ${_sample_proj_dir_absolute}
	    COMMENT "   Link pom.xml for project ${proj}/${_ver} "
	    )

	ADD_CUSTOM_TARGET(preprocess_publican_${proj}_${_ver}
	    DEPENDS ${_sample_proj_dir_absolute}/publican.cfg.striped
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${_sample_proj_dir_absolute}/publican.cfg.striped
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/preprocess_publican.sh "${LANGS}"
	    WORKING_DIRECTORY ${_sample_proj_dir_absolute}
	    DEPENDS ${_sample_proj_dir_absolute}/pot
	    COMMENT "   Preparing project ${proj}/${_ver} "
	    VERBATIM
	    )

	# Prepare project: generate zanata.xml and pom.xml
	ADD_CUSTOM_TARGET(prepare_${proj}_${_ver})

	ADD_DEPENDENCIES(prepare_${proj}_${_ver}
	    generate_zanata_xml_${proj}_${_ver}
	    link_pom_xml_${proj}_${_ver}
	    preprocess_publican_${proj}_${_ver}
	    )

	ADD_DEPENDENCIES(prepare_${proj} prepare_${proj}_${_ver})

	ADD_CUSTOM_COMMAND(OUTPUT ${_sample_proj_dir_absolute}/pot
	    COMMAND perl scripts/get_project.pl ${SAMPLE_PROJ_DIR_ABSOLUTE} ${proj}
	    ${${proj}_REPO_TYPE} ${_ver} ${${proj}_URL_${_ver}}
	    DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}
	    COMMENT "   Get sources of ${proj} ${_ver}:${${proj}_NAME} from ${${proj}_URL_${_ver}}"
	    VERBATIM
	    )

    ENDFOREACH(_ver ${_projVers})
ENDMACRO(ADD_PUBLICAN_PROJECT proj)

#===================================================================
# Maven targets
#
CONFIGURE_FILE(pom.xml.in pom.xml @ONLY)

SET(ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS
    -Dzanata.url=${ZANATA_URL} -Dzanata.userConfig=${CMAKE_SOURCE_DIR}/zanata.ini
    -Dzanata.username=${ADMIN_USER} -Dzanata.key=${ADMIN_KEY}
    )

MACRO(ADD_MVN_CLIENT_TARGETS proj )
    SET(_projVers "${${proj}_VERS}")

    ADD_CUSTOM_TARGET(zanata_putproject_mvn_${proj}
	COMMAND ${ZANATA_MVN_CMD} -e ${MVN_GOAL_PREFIX}:putproject
	${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	-Dzanata.project.slug=${proj}
	-Dzanata.project.name=${${proj}_NAME}
	-Dzanata.project.desc=${${proj}_DESC}
	COMMENT "  [Mvn] Creating proj: proj ${proj}:${${proj}_NAME} in ${ZANATA_URL}"
	VERBATIM
	)

    FOREACH(_ver ${_projVers})
	#MESSAGE("[mvn] proj=${proj} ver=${_ver}")
	SET(_pull_dest_dir_mvn ${PULL_DEST_DIR_ABSOLUTE}/mvn/${proj}/${_ver})
	SET(_sample_proj_dir_absolute ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/${_ver})
	SET(_zanata_xml_path ${_sample_proj_dir_absolute}/zanata.xml)

	SET(ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS
	    -Dzanata.projectConfig=${_zanata_xml_path}
	    -Dzanata.projectVersion=${_ver}
	    )

	# Put version
	ADD_CUSTOM_TARGET(zanata_putversion_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD} -e ${MVN_GOAL_PREFIX}:putversion
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dzanata.version.slug=${_ver}
	    -Dzanata.version.project=${proj}
	    -Dzanata.version.name=Ver\ ${_ver}
	    -Dzanata.version.desc=Desc\ of\ ${_ver}
	    DEPENDS ${_sample_proj_dir_absolute}/pom.xml
	    ${_zanata_xml_path}
	    ${_sample_proj_dir_absolute}/publican.cfg.striped
	    COMMENT "  [Mvn] Creating version: proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_putversion_mvn_${proj}_${_ver} zanata_putproject_mvn_${proj})

	# Publican push
	ADD_CUSTOM_TARGET(zanata_publican_push_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD} -e -B ${MVN_GOAL_PREFIX}:publican-push
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dzanata.srcDir=.
	    -Dzanata.importPo
	    WORKING_DIRECTORY ${_sample_proj_dir_absolute}
	    DEPENDS ${_sample_proj_dir_absolute}/pom.xml
	    ${_zanata_xml_path}
	    COMMENT "  [Mvn] Pushing pot and po for proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_publican_push_mvn_${proj}_${_ver} zanata_putversion_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(zanata_publican_push_mvn_all_projects
	    zanata_publican_push_mvn_${proj}_${_ver})


	# Publican pull
	ADD_CUSTOM_TARGET(zanata_publican_pull_mvn_${proj}_${_ver}
	    COMMAND ${ZANATA_MVN_CMD} -e -B ${MVN_GOAL_PREFIX}:publican-pull
	    ${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dzanata.dstDir=${_pull_dest_dir_mvn}
	    DEPENDS ${_zanata_xml_path}
	    ${_pull_dest_dir_mvn}
	    COMMENT "  [Mvn] Pulling pot and po for proj ${proj} ver ${_ver} from  ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_publican_pull_mvn_${proj}_${_ver}
	    zanata_publican_push_mvn_${proj}_${_ver}  zanata_putversion_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(zanata_publican_pull_mvn_all_projects
	    zanata_publican_pull_mvn_${proj}_${_ver})

	# REST test targets
	ADD_CUSTOM_TARGET(rest_test_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_mvn_${proj}_${_ver} zanata_publican_pull_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_mvn rest_test_mvn_${proj}_${_ver})

	ADD_CUSTOM_COMMAND(OUTPUT ${_pull_dest_dir_mvn}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_pull_dest_dir_mvn}
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
	COMMENT "  [Py] Creating proj: proj ${proj}:${${proj}_NAME} in ${ZANATA_URL}"
	VERBATIM
	)

    FOREACH(_ver ${_projVers})
	SET(_pull_dest_dir_py ${PULL_DEST_DIR_ABSOLUTE}/py/${proj}/${_ver})
	SET(_sample_proj_dir_absolute ${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}/${_ver})
	SET(_zanata_xml_path ${_sample_proj_dir_absolute}/zanata.xml)

	#MESSAGE("[py] proj=${proj} ver=${_ver}")
	SET(ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS
	    --project-id=${proj}
	    --project-version=${_ver}
	    )

	# Put version
	ADD_CUSTOM_TARGET(zanata_version_create_py_${proj}_${_ver}
	    COMMAND  ${ZANATA_PY_CMD} version create ${_ver}
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    --version-name=Ver\ ${_ver}
	    --version-desc=Desc\ of\ ${_ver}
	    WORKING_DIRECTORY ${_sample_proj_dir_absolute}
	    DEPENDS ${_zanata_xml_path}
	    ${_sample_proj_dir_absolute}/publican.cfg.striped
	    COMMENT "  [Py] Creating version: proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_version_create_py_${proj}_${_ver}
	    zanata_project_create_py_${proj})

	# Publican push
	ADD_CUSTOM_TARGET(zanata_publican_push_py_${proj}_${_ver}
	    COMMAND yes | ${ZANATA_PY_CMD} publican push
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    --import-po
	    --transdir=.
	    DEPENDS ${_zanata_xml_path}
	    WORKING_DIRECTORY ${_sample_proj_dir_absolute}
	    COMMENT "  [Py] Uploading pot and po for proj ${proj} ver ${_ver} to ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_publican_push_py_${proj}_${_ver} zanata_version_create_py_${proj}_${_ver})
	ADD_DEPENDENCIES(zanata_publican_push_py_all_projects
	    zanata_publican_push_py_${proj}_${_ver})

	# Publican pull
	ADD_CUSTOM_TARGET(zanata_publican_pull_py_${proj}_${_ver}
	    COMMAND ${ZANATA_PY_CMD} publican pull
	    ${ZANATA_PY_CLIENT_COMMON_ADMIN_OPTS}
	    ${ZANATA_PY_CLIENT_PRJ_ADMIN_OPTS}
	    --dstdir=${_pull_dest_dir_py}
	    DEPENDS ${_zanata_xml_path} ${_pull_dest_dir_py}
	    WORKING_DIRECTORY ${_sample_proj_dir_absolute}
	    COMMENT "  [Py] Pulling pot and po for proj ${proj} ver ${_ver} from  ${ZANATA_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(zanata_publican_pull_py_${proj}_${_ver}
	    zanata_publican_push_py_${proj}_${_ver}  zanata_version_create_py_${proj}_${_ver})
	ADD_DEPENDENCIES(zanata_publican_pull_py_all_projects
	    zanata_publican_pull_py_${proj}_${_ver})

	# REST test targets
	ADD_CUSTOM_TARGET(rest_test_py_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_py_${proj}_${_ver} zanata_publican_pull_py_${proj}_${_ver})
	ADD_DEPENDENCIES(rest_test_py rest_test_py_${proj}_${_ver})

	ADD_CUSTOM_COMMAND(OUTPUT ${_pull_dest_dir_py}
	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_pull_dest_dir_py}
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
	ADD_CUSTOM_TARGET(zanata_publican_push_${clientId}_all_projects
	    COMMENT "[${_clientDisplay}] publican push all projects."
	    )
	ADD_CUSTOM_TARGET(zanata_publican_pull_${clientId}_all_projects
	    COMMENT "[${_clientDisplay}] publican pull all projects."
	    )

	ADD_CUSTOM_TARGET(rest_test_${clientId}
	    COMMENT "[${_clientDisplay}] REST API tests."
	    )

	FOREACH(_proj ${${_clientDisplay}_PROJECTS})
	    GET_TARGET_PROPERTY(_target_exist prepare_${_proj} EXISTS)
	    IF(_target_exist STREQUAL "_target_exist-NOTFOUND")
		ADD_PUBLICAN_PROJECT(${_proj})
	    ENDIF(_target_exist STREQUAL "_target_exist-NOTFOUND")
	    IF("${clientId}" STREQUAL "py")
		ADD_PY_CLIENT_TARGETS(${_proj})
	    ELSE("${clientId}" STREQUAL "py")
		# MVN client
		ADD_MVN_CLIENT_TARGETS(${_proj})
	    ENDIF("${clientId}" STREQUAL "py")
	ENDFOREACH(_proj ${${_clientDisplay}_PROJECTS})
    ENDIF("${ZANATA_${_clientDisplay}_CMD}" STREQUAL "ZANATA_${_clientDisplay}_CMD-NOTFOUND")
ENDMACRO(GENERATE_REST_TEST_CLIENT_TARGETS clientId)

FIND_PROGRAM(ZANATA_MVN_CMD mvn)
GENERATE_REST_TEST_CLIENT_TARGETS(mvn)

# ZANATA_PY_PATH: The preferred location of zanata.
IF(NOT "${ZANATA_PY_PATH}" STREQUAL "")
    IF(NOT EXISTS ${ZANATA_PY_PATH})
	# Clone the python client if ZANATA_PY_PATH does not exist.
	FILE(MAKE_DIRECTORY ${ZANATA_PY_PATH})
	EXECUTE_PROCESS(COMMAND git clone ${PYTHON_CLIENT_REPO} ${ZANATA_PY_PATH})
    ENDIF(NOT EXISTS ${ZANATA_PY_PATH})
ENDIF(NOT "${ZANATA_PY_PATH}" STREQUAL "")

FIND_PROGRAM(ZANATA_PY_CMD zanata HINTS ${ZANATA_PY_PATH} /usr/bin /bin NO_DEFAULT_PATH)
GENERATE_REST_TEST_CLIENT_TARGETS(py)

#===================================================================
# Put users
#
ADD_CUSTOM_TARGET(putusers
    COMMENT "Create users in zanata server: ${ZANATA_URL}"
    )

MACRO(PUT_TEST_USER user)
    STRING(REGEX REPLACE ";" "," _lang  "${LANGS}")
    STRING(REGEX REPLACE "zh.CN" "zh-Hans" _lang  "${_lang}")
    STRING(REGEX REPLACE "zh.TW" "zh-Hant" _lang  "${_lang}")
    IF("${${user}_ROLES}" STREQUAL "")
	SET(ROLE_ASSIGN -Dzanata.user.roles=user)
    ELSE("${${user}_ROLES}" STREQUAL "")
	SET(ROLE_ASSIGN -Dzanata.user.roles=${${user}_ROLES})
    ENDIF("${${user}_ROLES}" STREQUAL "")

    SET(OPTS -Dzanata.user.disabled=false
	-Dzanata.user.email=${${user}_USER}@localhost.org
	-Dzanata.user.key=${${user}_KEY}
	-Dzanata.user.langs=${_lang}
	-Dzanata.user.name=${${user}_NAME}
	-Dzanata.user.username=${${user}_USER}
	-Dzanata.user.passwordhash=${${user}_PASSWD_HASH}
	)

    ADD_CUSTOM_TARGET(putuser_${user}
	COMMAND mvn -e ${MVN_GOAL_PREFIX}:putuser
	${ZANATA_MVN_CLIENT_COMMON_ADMIN_OPTS}
	${ROLE_ASSIGN}
	${OPTS}
	COMMENT "Create user ${${user}_USER} for ${user}"
	VERBATIM
	)
    ADD_DEPENDENCIES(putusers putuser_${user})
ENDMACRO(PUT_TEST_USER user)

FOREACH(_role ${TEST_ROLES})
    PUT_TEST_USER("${_role}")
ENDFOREACH(_role ${TEST_ROLES})

####################################################################
# Test Suites.
####################################################################
ENABLE_TESTING()
ADD_CUSTOM_TARGET(clean_test_suites
    COMMAND find selenium/src/test-suites -name "[1-9]*.html" -delete
    COMMAND find selenium/src/test-suites -name "SignIn*.html" -delete
    COMMAND find selenium/src/test-suites -name "SignOut.html" -delete
    COMMENT "Cleaning the generated test suite files"
    VERBATIM
    )

#===================================================================
# Generate test suites.
ADD_SUBDIRECTORY(selenium/src)

