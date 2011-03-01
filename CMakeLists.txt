cmake_minimum_required(VERSION 2.4)
####################################################################
# Init Definition
####################################################################
PROJECT(flies-tests NONE)
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
MESSAGE("CMake version=${CMAKE_VERSION}")

SET(ENV{LC_ALL} "C")

SET(TEST_CFG "test.cfg")
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR})
INCLUDE(ManageVariable)

####################################################################
# Project specific definition
####################################################################
SET(PROJECT_DESCRIPTION "Test system for flies.openl10n.net")


### Override with environment variables
SET(OVERRIDABLE_VARS  "FLIES_URL" "BROWSERS_TO_TEST" "SELENIUM_SERVER_PORT"
    "SAMPLE_PROJ_DIR" "PULL_DEST_DIR" "FLIES_PROFILE" "MVN_CLIENT_VER")
FOREACH(_envVar  ${OVERRIDABLE_VARS})
    IF(NOT "$ENV{${_envVar}}" STREQUAL "")
	SET(${_envVar} "$ENV{${_envVar}}")
    ENDIF()
ENDFOREACH()

SETTING_FILE_GET_ALL_VARIABLES("${TEST_CFG}" NOREPLACE UNQUOTED NOESCAPE_SEMICOLON)

# Assign PROFILE
IF(${FLIES_PROFILE} STREQUAL "")
    SET(FLIES_PROFILE fliesDevel)
ENDIF()
MESSAGE("FLIES_PROFILE=${FLIES_PROFILE}")
FOREACH(_var SERVER_BASE SERVER_PATH ADMIN_USER ADMIN_KEY TEST_ROLES KERBEROS)
    IF(DEFINED ${FLIES_PROFILE}_${_var})
	SET(${_var} "${${FLIES_PROFILE}_${_var}}")
	MESSAGE("Profile ${FLIES_PROFILE} specific: ${_var}=${${FLIES_PROFILE}_${_var}}")
    ENDIF(DEFINED ${FLIES_PROFILE}_${_var})
ENDFOREACH()
SET(FLIES_URL ${SERVER_BASE}${SERVER_PATH})

### Print variables
FOREACH(_envVar  ${OVERRIDABLE_VARS})
    SET(_envVal "${${_envVar}}")
    MESSAGE("${_envVar}=${_envVal}")
ENDFOREACH()

SET(TEST_ROOT_ABSOLUTE "${CMAKE_SOURCE_DIR}/${TEST_ROOT}")
SET(PRIVILEGE_TEST_ROOT_ABSOLUTE "${CMAKE_SOURCE_DIR}/${PRIVILEGE_TEST_ROOT}")
SET(RESULT_DIR_ABSOLUTE "${CMAKE_SOURCE_DIR}/${RESULT_DIR}")

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
	OUTPUT_VARIABLE _result)
    #MESSAGE("_result=${_result}")
    IF ( _result STREQUAL "NOT_FOUND")
	SET(${var} "NOTFOUND")
    ELSE()
	STRING_TRIM( _result "${_result}")
	SET( ${var} "${_result}")
    ENDIF()
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

SET(FLIES_MVN_GOAL_PREFIX  "net.openl10n.flies:flies-maven-plugin")
#SET(FLIES_MVN_GOAL_PREFIX  "flies")

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

FIND_PROGRAM(FLIES_PY_CMD flies)
IF(${FLIES_PY_CMD} STREQUAL "FLIES_PY_CMD-NOTFOUND")
    MESSAGE("flies python client (flies) is not installed! Python tests  disabled")
ENDIF(${FLIES_PY_CMD} STREQUAL "FLIES_PY_CMD-NOTFOUND")

####################################################################
# Configure
#

#===================================================================
# Python targets
#
SET(FLIES_PY_CLIENT_COMMON_ADMIN_OPTS --username ${ADMIN_USER} --apikey ${ADMIN_KEY}
    --url ${FLIES_URL} --user-config ${CMAKE_SOURCE_DIR}/flies.ini)

MACRO(ADD_PY_CLIENT_TARGETS proj )
    SET(_projVers "${${proj}_VERS}")
    ADD_CUSTOM_TARGET(flies_putproject_py_${proj}
	COMMAND ${FLIES_PY_CMD} create ${proj}
	${FLIES_PY_CLIENT_COMMON_ADMIN_OPTS}
	--project-name=${${proj}_NAME}
	--project-desc=${${proj}_DESC}
	COMMENT "  [Py] Creating proj: proj ${proj}:${${proj}_NAME} in ${FLIES_URL}"
	VERBATIM
	)

    FOREACH(_ver ${_projVers})
	#MESSAGE("[py] proj=${proj} ver=${_ver}")
	SET(FLIES_PY_CLIENT_PRJ_ADMIN_OPTS
	    -Dflies.projectConfig=${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    -Dflies.projectVersion=${_ver}
	    )

	# Put version
	ADD_CUSTOM_TARGET(flies_putversion_py_${proj}_${_ver}
	    COMMAND  ${FLIES_PY_CMD} version create ${_ver}
	    ${FLIES_PY_CLIENT_COMMON_ADMIN_OPTS}
	    --project-id=${proj}
	    --version-name=Ver\ ${_ver}
	    --version-desc=Desc\ of\ ${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMENT "  [Py] Creating version: proj ${proj} ver ${_ver} to ${FLIES_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(flies_putversion_py_${proj}_${_ver} flies_putproject_py_${proj})

	# Publican push
	ADD_CUSTOM_TARGET(flies_publican_push_py_${proj}_${_ver}
	    COMMAND ${FLIES_PY_CMD} publican push
	    ${FLIES_PY_CLIENT_COMMON_ADMIN_OPTS}
	    --project-id=${proj}
	    --project-version=${_ver}
	    --importPo
	    --srcDir=.
	    --transDir=.
	    WORKING_DIRECTORY ${SAMPLE_PROJ_DIR}/${proj}/${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMENT "  [Py] Uploading pot and po for proj ${proj} ver ${_ver} to ${FLIES_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(flies_publican_push_py_${proj}_${_ver} flies_putversion_py_${proj}_${_ver})
	ADD_DEPENDENCIES(flies_publican_push_py_all_projects
	    flies_publican_push_py_${proj}_${_ver})

	# Publican pull
	ADD_CUSTOM_TARGET(flies_publican_pull_py_${proj}_${_ver}
	    COMMAND ${FLIES_PY_CMD} publican pull
	    ${FLIES_PY_CLIENT_COMMON_ADMIN_OPTS}
	    --project-id=${proj}
	    --project-version=${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMENT "  [Py] Pulling pot and po for proj ${proj} ver ${_ver} from  ${FLIES_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(flies_publican_pull_py_${proj}_${_ver}
	    flies_publican_push_py_${proj}_${_ver} flies_putversion_py_${proj}_${_ver})

	ADD_DEPENDENCIES(flies_publican_pull_py_all_projects
	    flies_publican_pull_py_${proj}_${_ver})
    ENDFOREACH(_ver ${_projVers})
ENDMACRO(ADD_PY_CLIENT_TARGETS proj)

#===================================================================
# Maven targets
#
CONFIGURE_FILE(pom.xml.in pom.xml @ONLY)

SET(FLIES_MVN_CLIENT_COMMON_ADMIN_OPTS
    -Dflies.url=${FLIES_URL} -Dflies.userConfig=${CMAKE_SOURCE_DIR}/flies.ini
    -Dflies.username=${ADMIN_USER} -Dflies.key=${ADMIN_KEY}
    )

MACRO(ADD_MVN_CLIENT_TARGETS proj )
    SET(_projVers "${${proj}_VERS}")

    ADD_CUSTOM_TARGET(flies_putproject_mvn_${proj}
	COMMAND mvn -e ${FLIES_MVN_GOAL_PREFIX}:putproject
	${FLIES_MVN_CLIENT_COMMON_ADMIN_OPTS}
	-Dflies.project.slug=${proj}
	-Dflies.project.name=${${proj}_NAME}
	-Dflies.project.desc=${${proj}_DESC}
	COMMENT "  [Mvn] Creating proj: proj ${proj}:${${proj}_NAME} in ${FLIES_URL}"
	VERBATIM
	)

    FOREACH(_ver ${_projVers})
	#MESSAGE("[mvn] proj=${proj} ver=${_ver}")
	SET(FLIES_MVN_CLIENT_PRJ_ADMIN_OPTS
	    -Dflies.projectConfig=${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    -Dflies.projectVersion=${_ver}
	    )

	# Put version
	ADD_CUSTOM_TARGET(flies_putversion_mvn_${proj}_${_ver}
	    COMMAND mvn -e ${FLIES_MVN_GOAL_PREFIX}:putversion
	    ${FLIES_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${FLIES_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dflies.version.slug=${_ver}
	    -Dflies.version.project=${proj}
	    -Dflies.version.name=Ver\ ${_ver}
	    -Dflies.version.desc=Desc\ of\ ${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pom.xml
	    ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMENT "  [Mvn] Creating version: proj ${proj} ver ${_ver} to ${FLIES_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(flies_putversion_mvn_${proj}_${_ver} flies_putproject_mvn_${proj})

	# Publican push
	ADD_CUSTOM_TARGET(flies_publican_push_mvn_${proj}_${_ver}
	    COMMAND  mvn -e -B ${FLIES_MVN_GOAL_PREFIX}:publican-push
	    ${FLIES_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${FLIES_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dflies.copyTrans=false
	    -Dflies.srcDir=.
	    -Dflies.importPo
	    WORKING_DIRECTORY ${SAMPLE_PROJ_DIR}/${proj}/${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pom.xml
	    ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMENT "  [Mvn] Pushing pot and po for proj ${proj} ver ${_ver} to ${FLIES_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(flies_publican_push_mvn_${proj}_${_ver} flies_putversion_mvn_${proj}_${_ver})
	ADD_DEPENDENCIES(flies_publican_push_mvn_all_projects
	    flies_publican_push_mvn_${proj}_${_ver})

	# Publican pull
	ADD_CUSTOM_TARGET(flies_publican_pull_mvn_${proj}_${_ver}
	    COMMAND  mvn -e -B ${FLIES_MVN_GOAL_PREFIX}:publican-pull
	    ${FLIES_MVN_CLIENT_COMMON_ADMIN_OPTS}
	    ${FLIES_MVN_CLIENT_PRJ_ADMIN_OPTS}
	    -Dflies.dstDir=${PULL_DEST_DIR}/${proj}/${_ver}
	    -Dflies.exportPot
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMENT "  [Mvn] Pulling pot and po for proj ${proj} ver ${_ver} from  ${FLIES_URL}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(flies_publican_pull_mvn_${proj}_${_ver}
	    flies_publican_push_mvn_${proj}_${_ver} flies_putversion_mvn_${proj}_${_ver})

	ADD_DEPENDENCIES(flies_publican_pull_mvn_all_projects
	    flies_publican_pull_mvn_${proj}_${_ver})
    ENDFOREACH(_ver ${_projVers})
ENDMACRO(ADD_MVN_CLIENT_TARGETS proj)

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

    FOREACH(_ver ${_projVers})
	ADD_CUSTOM_TARGET(generate_flies_xml_${proj}_${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml
	    COMMAND scripts/generate_flies_xml.sh ${SAMPLE_PROJ_DIR} ${proj}
	    ${_ver} ${FLIES_URL} "${LANGS}"
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pot
	    COMMENT "   Generate ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/flies.xml"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(link_pom_xml_${proj}_${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pom.xml
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pom.xml
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/link_pom_xml.sh ${CMAKE_SOURCE_DIR}
	    WORKING_DIRECTORY ${SAMPLE_PROJ_DIR}/${proj}/${_ver}
	    COMMENT "   Link pom.xml for project ${proj}/${_ver} "
	    )

	ADD_CUSTOM_TARGET(preprocess_publican_${proj}_${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/publican.cfg.striped
	    )

	ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/publican.cfg.striped
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/preprocess_publican.sh "${LANGS}"
	    WORKING_DIRECTORY ${SAMPLE_PROJ_DIR}/${proj}/${_ver}
	    DEPENDS ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pot
	    COMMENT "   Preparing project ${proj}/${_ver} "
	    VERBATIM
	    )

	# Prepare project: generate flies.xml and pom.xml
	ADD_CUSTOM_TARGET(prepare_${proj}_${_ver})

	ADD_DEPENDENCIES(prepare_${proj}_${_ver}
	    generate_flies_xml_${proj}_${_ver}
	    link_pom_xml_${proj}_${_ver}
	    preprocess_publican_${proj}_${_ver}
	    )

	ADD_DEPENDENCIES(prepare_${proj} prepare_${proj}_${_ver})

	ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR}/${proj}/${_ver}/pot
	    COMMAND perl scripts/get_project.pl ${SAMPLE_PROJ_DIR} ${proj}
	    ${${proj}_REPO_TYPE} ${_ver} ${${proj}_URL_${_ver}}
	    DEPENDS ${SAMPLE_PROJ_DIR}
	    COMMENT "   Get sources of ${proj} ${_ver}:${${proj}_NAME} from ${${proj}_URL_${_ver}}"
	    VERBATIM
	    )

	ADD_DEPENDENCIES(prepare_all_projects generate_pom_xml_${proj}_${_ver})

	ADD_CUSTOM_COMMAND(OUTPUT ${PULL_DEST_DIR}/${proj}/${_ver}
	    COMMAND cmake -E make_directory ${PULL_DEST_DIR}/${proj}/${_ver}
	    COMMENT "   Mkdir for pulling ${proj}/${_ver}/ to ${PULL_DEST_DIR}"
	    )
    ENDFOREACH(_ver ${_projVers})
ENDMACRO(ADD_PUBLICAN_PROJECT proj)

ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR}
    COMMAND mkdir -p ${SAMPLE_PROJ_DIR}
    )

####################################################################
# Retrieve projects
#

ADD_CUSTOM_TARGET(prepare_all_projects
    COMMENT "Prepare all projects"
    )
ADD_CUSTOM_TARGET(flies_publican_push_mvn_all_projects
    COMMENT "[MVN] publican push all projects"
    )
ADD_CUSTOM_TARGET(flies_publican_pull_mvn_all_projects
    COMMENT "[MVN] publican pull all projects"
    )

ADD_CUSTOM_TARGET(flies_publican_push_py_all_projects
    COMMENT "[PY] publican push all projects"
    )

ADD_CUSTOM_TARGET(flies_publican_pull_py_all_projects
    COMMENT "[PY] publican pull all projects"
    )


ADD_CUSTOM_TARGET(all_projects)

ADD_DEPENDENCIES(all_projects
    flies_publican_pull_mvn_all_projects
    flies_publican_push_py_all_projects )

FOREACH(_proj ${MVN_PROJECTS})
    ADD_PUBLICAN_PROJECT(${_proj})
    ADD_MVN_CLIENT_TARGETS(${_proj})
ENDFOREACH(_proj ${MVN_PROJECTS})

IF(NOT ${FLIES_PY_CMD} STREQUAL "FLIES_PY_CMD-NOTFOUND")
    FOREACH(_proj ${PY_PROJECTS})
	# Check whether the projects are prepared already
	GET_TARGET_PROPERTY(_target_location prepare_${_proj} LOCATION)
	IF(_target_location STREQUAL "NOTFOUND")
	    ADD_PUBLICAN_PROJECT(${_proj})
	ENDIF(_target_location STREQUAL "NOTFOUND")
	ADD_PY_CLIENT_TARGETS(${_proj})
    ENDFOREACH(_proj ${PY_PROJECTS})
ENDIF(NOT ${FLIES_PY_CMD} STREQUAL "FLIES_PY_CMD-NOTFOUND")


ADD_CUSTOM_TARGET(selenium_projects
	COMMENT "   Preparing projects for selenium tests"
)

ADD_CUSTOM_TARGET(prepare_selenium_projects
    COMMENT "   Generate flies.xml for selenium testing projects"
    )

ADD_DEPENDENCIES(prepare_selenium_projects
    prepare_ReleaseNotes_f13 prepare_SecurityGuide_f13)

ADD_DEPENDENCIES(selenium_projects flies_publican_push_mvn_ReleaseNotes_f13
    flies_publican_push_mvn_SecurityGuide_f13)

#===================================================================
# Put users
#
ADD_CUSTOM_TARGET(putusers
    COMMENT "Create users in flies server: ${FLIES_URL}"
    )

MACRO(PUT_TEST_USER user)
    STRING(REGEX REPLACE ";" "," _lang  "${LANGS}")
    STRING(REGEX REPLACE "zh.CN" "zh-Hans" _lang  "${_lang}")
    STRING(REGEX REPLACE "zh.TW" "zh-Hant" _lang  "${_lang}")
    IF("${${user}_ROLES}" STREQUAL "")
	SET(ROLE_ASSIGN -Dflies.user.roles=user)
    ELSE("${${user}_ROLES}" STREQUAL "")
	SET(ROLE_ASSIGN -Dflies.user.roles=${${user}_ROLES})
    ENDIF("${${user}_ROLES}" STREQUAL "")

    SET(OPTS -Dflies.user.disabled=false
	-Dflies.user.email=${${user}_USER}@localhost.org
	-Dflies.user.key=${${user}_KEY}
	-Dflies.user.langs=${_lang}
	-Dflies.user.name=${${user}_NAME}
	-Dflies.user.username=${${user}_USER}
	-Dflies.user.passwordhash=${${user}_PASSWD_HASH}
	)

    ADD_CUSTOM_TARGET(putuser_${user}
	COMMAND mvn -e ${FLIES_MVN_GOAL_PREFIX}:putuser
	${FLIES_MVN_CLIENT_COMMON_ADMIN_OPTS}
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
    COMMAND find selenium/src/test-suites -type l -name "SignIn*.html" -delete
    COMMAND find selenium/src/test-suites -type l -name "SignOut.html" -delete
    COMMENT "Cleaning the generated test suite files"
    VERBATIM
    )

#===================================================================
# Generate test suites.
ADD_SUBDIRECTORY(selenium/src)

