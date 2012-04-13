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
INCLUDE(ManageUrl)

####################################################################
# Project specific definition
####################################################################
SET(PROJECT_DESCRIPTION "Test system for project Zanata")

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
    "ZANATA_PY_PATH" "PY_PROJECTS" "MVN_PROJECTS" "COPY_TRANS")
FOREACH(_envVar  ${OVERRIDABLE_VARS})
    IF(NOT "$ENV{${_envVar}}" STREQUAL "")
	SET(${_envVar} "$ENV{${_envVar}}")
    ENDIF()
ENDFOREACH()

SETTING_FILE_GET_ALL_VARIABLES("${TEST_CFG}" NOREPLACE NOESCAPE_SEMICOLON)
SET(SCRIPT_DIR ${CMAKE_SOURCE_DIR}/scripts)

####################################################################
# Profiles
####################################################################

#===================================================================
# Apply profile variable
#
MESSAGE("ZANATA_PROFILE=${ZANATA_PROFILE}")
SET(PROFILE_VARIABLES SERVER_URL ADMIN_USER ADMIN_KEY TEST_ROLES KERBEROS
    AUTH_METHOD LOGIN_FIELD_ID PASSWORD_FIELD_ID MVN_CLIENT_VER)
FOREACH(_var ${PROFILE_VARIABLES})
    IF(DEFINED ${ZANATA_PROFILE}_${_var})
	SET(${_var} "${${ZANATA_PROFILE}_${_var}}")
	MESSAGE("Profile ${ZANATA_PROFILE} specific: ${_var}=${${ZANATA_PROFILE}_${_var}}")
    ENDIF(DEFINED ${ZANATA_PROFILE}_${_var})

    IF("${${_var}}" STREQUAL "")
	SET(${_var} "${${_var}_DEFAULT}")
    ENDIF()
ENDFOREACH()
GET_URL_COMPONENT(SERVER_SCHEME "${SERVER_URL}" SCHEME)
GET_URL_COMPONENT(SERVER_AUTHORITY "${SERVER_URL}" AUTHORITY)
GET_URL_COMPONENT(SERVER_PATH "${SERVER_URL}" PATH)
GET_URL_COMPONENT(SERVER_HOST "${SERVER_URL}" HOSTNAME)
MESSAGE("SERVER_PATH=${SERVER_PATH}")

SET(SERVER_BASE "${SERVER_SCHEME}://${SERVER_AUTHORITY}")
MESSAGE("SERVER_BASE=${SERVER_BASE}")
SET(ZANATA_URL "${SERVER_BASE}${SERVER_PATH}")

### Print variables
FOREACH(_envVar  ${OVERRIDABLE_VARS})
    SET(_envVal "${${_envVar}}")
    MESSAGE("${_envVar}=${_envVal}")
ENDFOREACH()

#===================================================================
# Write profiles to zanata.ini
#

SET(ZANATA_INI zanata.ini)
FILE(REMOVE ${ZANATA_INI})
EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy zanata.ini.in ${ZANATA_INI})

FOREACH(_pf ${SERVER_PROFILES})
    FILE(APPEND ${ZANATA_INI} "${_pf}.url=${${_pf}_SERVER_URL}\n")
    IF("${${_pf}_ADMIN_USER}" STREQUAL "")
	FILE(APPEND ${ZANATA_INI} "${_pf}.username=${ADMIN_USER_DEFAULT}\n")
    ELSE("${${_pf}_ADMIN_USER}" STREQUAL "")
	FILE(APPEND ${ZANATA_INI} "${_pf}.username=${${_pf}_ADMIN_USER}\n")
    ENDIF("${${_pf}_ADMIN_USER}" STREQUAL "")

    IF("${${_pf}_ADMIN_KEY}" STREQUAL "")
	FILE(APPEND ${ZANATA_INI} "${_pf}.key=${ADMIN_KEY_DEFAULT}\n")
    ELSE("${${_pf}_ADMIN_KEY}" STREQUAL "")
	FILE(APPEND ${ZANATA_INI} "${_pf}.key=${${_pf}_ADMIN_KEY}\n")
    ENDIF("${${_pf}_ADMIN_KEY}" STREQUAL "")
    FILE(APPEND ${ZANATA_INI} "\n")
ENDFOREACH(_pf ${SERVER_PROFILES})

#===================================================================
# Test environment
#
REAL_PATH(TEST_ROOT_ABSOLUTE "${TEST_ROOT}")
REAL_PATH(PRIVILEGE_TEST_ROOT_ABSOLUTE "${PRIVILEGE_TEST_ROOT}")
REAL_PATH(RESULT_DIR_ABSOLUTE "${RESULT_DIR}")

REAL_PATH(SAMPLE_PROJ_DIR_ABSOLUTE "${SAMPLE_PROJ_DIR}")
REAL_PATH(PULL_DEST_DIR_ABSOLUTE "${PULL_DEST_DIR}")

SET(TEST_ROOT_ABSOLUTE "${CMAKE_SOURCE_DIR}/${TEST_ROOT}")
SET(PRIVILEGE_TEST_ROOT_ABSOLUTE "${CMAKE_SOURCE_DIR}/${PRIVILEGE_TEST_ROOT}")
SET(RESULT_DIR_ABSOLUTE "${CMAKE_SOURCE_DIR}/${RESULT_DIR}")

# Maven
SET(MVN_GOAL_PREFIX "zanata")

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
    EXECUTE_PROCESS(COMMAND ${SCRIPT_DIR}/find_file_in_paths.sh ${pattern} "${searchPaths}"
	OUTPUT_VARIABLE _result OUTPUT_STRIP_TRAILING_WHITESPACE)
    MESSAGE("FIND_FILE_IN_DIRS ${var} _result=${_result}")
    SET( ${var} "${_result}")
ENDMACRO()

MACRO(FIND_FILES_IN_DIR var pattern searchPath)
    EXECUTE_PROCESS(COMMAND find ${searchPath} -name "${pattern}" -printf "%p;"
	OUTPUT_VARIABLE _result  OUTPUT_STRIP_TRAILING_WHITESPACE)
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

INCLUDE(RestTest)

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

####################################################################
# Other targets
####################################################################
ADD_CUSTOM_TARGET(restart_jboss
    COMMAND ssh jboss@${SERVER_HOST} JBOSS_USER=RUNASIS /etc/init.d/jbossewp5 restart
    COMMENT "Restart JBOSS"
    )

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
	SET(ROLE_ASSIGN -Dzanata.userRoles=user)
    ELSE("${${user}_ROLES}" STREQUAL "")
	SET(ROLE_ASSIGN -Dzanata.userRoles=${${user}_ROLES})
    ENDIF("${${user}_ROLES}" STREQUAL "")

    SET(OPTS -Dzanata.userDisabled=false
	-Dzanata.userEmail=${${user}_USER}@${SERVER_HOST}
	-Dzanata.userKey=${${user}_KEY}
	-Dzanata.userLangs=${_lang}
	-Dzanata.userName=${${user}_NAME}
	-Dzanata.userUsername=${${user}_USER}
	-Dzanata.userPasswordHash=${${user}_PASSWD_HASH}
	)

    ADD_CUSTOM_TARGET(putuser_${user}
	COMMAND mvn -e -U ${MVN_GOAL_PREFIX}:putuser
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

