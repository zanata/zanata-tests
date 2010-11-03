cmake_minimum_required(VERSION 2.4)
####################################################################
# Init Definition
####################################################################
PROJECT(flies-test NONE)
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
MESSAGE("CMake version=${CMAKE_VERSION}")

SET(ENV{LC_ALL} "C")

SET(TEST_CFG "${CMAKE_SOURCE_DIR}/test.cfg")
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR})
INCLUDE(ManageVariable)

####################################################################
# Project specific definition
####################################################################
# PROJECT(flies-test) # CTest does not recognize that.
SET(PROJECT_DESCRIPTION "Test system for flies.openl10n.net")

IF (NOT "$ENV{BASE_URL}" STREQUAL "")
    SET(BASE_URL $ENV{BASE_URL})
ENDIF()

IF (NOT "$ENV{BROWSERS_TO_TEST}" STREQUAL "")
    SET(BROWSERS_TO_TEST $ENV{BROWSERS_TO_TEST})
ENDIF()

SETTING_FILE_GET_ALL_VARIABLES("${TEST_CFG}" NOREPLACE UNQUOTED NOESCAPE_SEMICOLON)

MESSAGE("BASE_URL=${BASE_URL}")
MESSAGE("FLIES_PATH=${FLIES_PATH}")
MESSAGE("FLIES_URL=${FLIES_URL}")
SET(RESULT_DIR "${CMAKE_SOURCE_DIR}/${RESULT_DIR}")
SET(FUNCTIONS_DIR "${CMAKE_SOURCE_DIR}/${FUNCTIONS_DIR}")

MESSAGE("BROWSERS_TO_TEST=${BROWSERS_TO_TEST}")

SET(TEST_ROOT_REAL "${CMAKE_SOURCE_DIR}/${TEST_ROOT}")
SET(PRIVILEGE_TEST_ROOT_REAL "${CMAKE_SOURCE_DIR}/${PRIVILEGE_TEST_ROOT}")
SET(TEST_ROLES ADMIN NORMAL)

#===================================================================
# Selenium server port is from environment variable ${SELENIUM_SERVER_PORT}
GET_ENV(SELENIUM_SERVER_PORT "4444")
MESSAGE("SELENIUM_SERVER_PORT=${SELENIUM_SERVER_PORT}")

#===================================================================
# Search Paths
SET(MAVEN_REPOSITORY "$ENV{HOME}/.m2/repository/")
SET(MAVEN_SELENIUM_SERVER_PATH "${MAVEN_REPOSITORY}/org/seleniumhq/selenium/server/selenium-server/")
SET(SELENIUM_SEARCH_PATHS $ENV{HOME} ${MAVEN_SELENIUM_SERVER_PATH} /usr/share/java ${PWD})
SET(firefox_SEARCH_PATHS
    "/usr/lib64/firefox-3.6;/usr/lib/firefox-3.6;/usr/lib64/firefox-3.5;/usr/lib/firefox-3.5;/usr/lib64/firefox-3*;/usr/lib/firefox-3*;/usr/lib64/firefox*;/usr/lib/firefox*")


#===================================================================
# Macro FIND_FILE_IN_DIRS
MACRO(FIND_FILE_IN_DIRS var pattern searchPaths)
    #MESSAGE("pattern=${pattern} searchPaths=${searchPaths}")
    EXECUTE_PROCESS(COMMAND ${CMAKE_SOURCE_DIR}/find_file_in_paths.sh ${pattern} "${searchPaths}"
	OUTPUT_VARIABLE _result)
    #MESSAGE("_result=${_result}")
    IF ( _result STREQUAL "NOT_FOUND")
	SET(${var} "NOTFOUND")
    ELSE()
	STRING_TRIM( _result ${_result})
	SET(${var} ${_result})
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

####################################################################
# Dependencies
####################################################################
FIND_PROGRAM(CTEST_COMMAND ctest)
IF( ${CTEST_COMMAND} STREQUAL "CTEST_COMMAND-NOTFOUND" )
    MESSAGE(SEND_ERROR "ctest not found, install it please.")
ENDIF()

FIND_PROGRAM(SELENIUM_SERVER_CMD selenium-server)
IF(${SELENIUM_SERVER_CMD} STREQUAL "SELENIUM_SERVER_CMD-NOTFOUND")
    # find selenium server jar
    FIND_FILE_IN_DIRS(SELENIUM_SERVER_JAR "selenium-server*.jar" "${SELENIUM_SEARCH_PATHS}")
    IF ("${SELENIUM_SERVER_JAR}" STREQUAL "NOTFOUND")
        MESSAGE(FATAL_ERROR "selenium-server not found, install it please.")
    ENDIF()
    SET(SELENIUM_SERVER_CMD java -jar ${SELENIUM_SERVER_JAR})
ENDIF()
#MESSAGE("SELENIUM_SERVER_CMD=${SELENIUM_SERVER_CMD}")

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
# Test Suites.
####################################################################
ENABLE_TESTING()

#===================================================================
# Generate test suites.
MESSAGE("TEST_ROOT=${TEST_ROOT}")
FIND_FILES_IN_DIR(TEST_SUITES_RAW  "0-*.html" "${TEST_ROOT}")

MESSAGE("TEST_SUITES_RAW=${TEST_SUITES_RAW}")

LIST(APPEND SELENIUM_SERVER_ARG -port ${SELENIUM_SERVER_PORT} -debug)

## General tests
MESSAGE("Generate General tests")
FOREACH(testSuiteRaw ${TEST_SUITES_RAW})
    GET_FILENAME_COMPONENT(testSuitePath ${testSuiteRaw} PATH)
    GET_FILENAME_COMPONENT(testSuiteNameOrig ${testSuiteRaw} NAME_WE)
    STRING(REGEX REPLACE "^0-" "" testSuiteName ${testSuiteNameOrig})

    # Make test rules.
    #    ADD_OUTPUT_AND_TEST(NORMAL ${testSuitePath} ${testSuiteName})
    ADD_OUTPUT_AND_TEST(${testSuitePath} ${testSuiteName})
ENDFOREACH(testSuiteRaw ${TEST_SUITES_RAW})

## Privilege tests
EXECUTE_PROCESS(COMMAND ${CMAKE_SOURCE_DIR}/generate_privilege_test_suite.sh ${PRIVILEGE_TEST_ROOT_REAL})
ADD_OUTPUT_FOR_BROWSERS(${PRESIGNIN_TEST_SUITE_NAME} PRE_LOGIN ${PRIVILEGE_TEST_ROOT_REAL}/${PRESIGNIN_TEST_SUITE} )
ADD_OUTPUT_FOR_BROWSERS(${NORMAL_TEST_SUITE_NAME} NORMAL ${PRIVILEGE_TEST_ROOT_REAL}/${NORMAL_TEST_SUITE_SISO} )

IF(NOT EXISTS ${RESULT_DIR})
    file(MAKE_DIRECTORY ${RESULT_DIR})
ENDIF()

MACRO(ADD_OUTPUT_FOR_BROWSERS testSuiteName testRole suiteFile)
    FOREACH(browser ${BROWSERS_TO_TEST})
	SET(BROWSER_STR "*${browser}\\ ${${browser}_BIN}")
	ADD_TEST("${testSuiteName}.${testRole}.${browser}"
	    ${SELENIUM_SERVER_CMD} ${SELENIUM_SERVER_ARG} -log
	    ${RESULT_DIR}/${testSuiteName}.${testRole}.${browser}.${TEST_LOGFILE_POSTFIX}
	    -java
	    -htmlsuite ${BROWSER_STR} ${BASE_URL}  ${suiteFile}
	    ${RESULT_DIR}/${testSuiteName}.${testRole}.${browser}.html)
    ENDFOREACH()
ENDMACRO()

MACRO(ADD_OUTPUT_AND_TEST testSuitePath testSuiteName)
    IF (EXISTS "${testSuitePath}/TEST_PRELOGIN")
	SET(_testRoles ${TEST_ROLES} PRELOGIN)
    ELSE()
	SET(_testRoles ${TEST_ROLES})
    ENDIF()
    MESSAGE("testPath=${testSuitePath}")
    FOREACH(testRole ${_testRoles})
	IF (NOT EXISTS "${testSuitePath}/NO_${testRole}" )
	    IF ( ${testRole} STREQUAL "PRELOGIN" )
		SET(suiteFile ${testSuitePath}/0-${testSuiteName}.html)
	    ELSE()
		IF ( ${testRole} STREQUAL "ADMIN" )
		    SET(SISO_TEST_TARGET 2-${testSuiteName}.html)
		    SET(SI_TEST_TARGET   1-${testSuiteName}.html)
		    SET(suiteFile ${testSuitePath}/${SISO_TEST_TARGET})
		ELSE()
		    SET(SISO_TEST_TARGET 4-${testSuiteName}.html)
		    SET(SI_TEST_TARGET   3-${testSuiteName}.html)
		    SET(suiteFile ${testSuitePath}/${SISO_TEST_TARGET})
		ENDIF()
		EXECUTE_PROCESS(COMMAND ${CMAKE_SOURCE_DIR}/generate_test_suite.sh
		    ${testRole} ${testSuitePath} ${testSuiteName} ${SI_TEST_TARGET} ${SISO_TEST_TARGET} ${TEST_ROOT_REAL}
		    )
	    ENDIF()
	    ADD_OUTPUT_FOR_BROWSERS(${testSuiteName} "${testRole}" ${suiteFile} )
	ENDIF()
    ENDFOREACH()
ENDMACRO(ADD_OUTPUT_AND_TEST testRole testSuitePath testSuiteName)

#===================================================================
# Write CTestTestfile.cmake

#SET(CTESTTEST_CMAKE "${CTEST_BINARY_DIRECTORY}/CTestTestfile.cmake")



