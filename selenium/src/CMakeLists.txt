####################################################################
# Test Settings
#

SET(BROWSER_DEFAULT "firefox")
IF("${BROWSER}" STREQUAL "")
    SET(BROWSER ${BROWSER_DEFAULT})
ENDIF("${BROWSER}" STREQUAL "")
SET(BROWSER_STR "*${BROWSER}\\ ${${BROWSER}_BIN}")

# MESSAGE("TEST_ROOT_ABSOLUTE=${TEST_ROOT_ABSOLUTE}")
FIND_FILES_IN_DIR(TEST_SUITES_RAW  "0-*.html" "${TEST_ROOT_ABSOLUTE}")

# MESSAGE("TEST_SUITES_RAW=${TEST_SUITES_RAW}")

#===================================================================
# Selenium settings
#
# Flow control extension
SET(SELENIUM_EXTENSION
    "${CMAKE_SOURCE_DIR}/selenium/dependencies/user-extensions.js")

LIST(APPEND SELENIUM_SERVER_ARG -port ${SELENIUM_SERVER_PORT} -debug
    -userExtensions ${SELENIUM_EXTENSION})


####################################################################
# Maintenance targets and macros
#
#===================================================================
# Initial server setup

SET(INITIAL_SETUP_SCRIPT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/initial_setup)
CONFIGURE_FILE(${INITIAL_SETUP_SCRIPT_DIR}/ServerConfiguration.html.in
    ${INITIAL_SETUP_SCRIPT_DIR}/ServerConfiguration.html @ONLY)

CONFIGURE_FILE(${INITIAL_SETUP_SCRIPT_DIR}/ManageLanguages.html.in
    ${INITIAL_SETUP_SCRIPT_DIR}/ManageLanguages.html @ONLY)

SET(SIGN_IN_USER "${ADMIN_USER}")
SET(SIGN_IN_PASSWD "${ADMIN_PASSWD}")

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/functions/SignIn.html.in
    ${INITIAL_SETUP_SCRIPT_DIR}/SignInAdmin.html @ONLY)

ADD_CUSTOM_TARGET(initial_setup
    ${SELENIUM_SERVER_CMD} ${SELENIUM_SERVER_ARG}
    -port ${SELENIUM_SERVER_PORT}
    -log ${RESULT_DIR_ABSOLUTE}/initial_setup.test.log
    -htmlsuite "*firefox\ ${firefox_BIN}" ${ZANATA_URL}  ${INITIAL_SETUP_SCRIPT_DIR}/00-InitSetup.html
    ${RESULT_DIR_ABSOLUTE}/initial_setup.html
    VERBATIM
    )

####################################################################
# Test generating macros
#

# Generate test suite for each browser
MACRO(GENERATE_TEST_FOREACH_BROWSER testSuiteDir testSuiteName testRole suiteFile)
    IF(EXISTS "${testSuiteDir}/UNSTABLE")
	SET(_unstablePrefix "US-")
    ELSE()
	SET(_unstablePrefix "")
    ENDIF()

    FOREACH(browser ${BROWSERS_TO_TEST})
	SET(BROWSER_STR "*${browser}\\ ${${browser}_BIN}")

	ADD_TEST("${_unstablePrefix}${testSuiteName}.${testRole}.${browser}"
	    ${SELENIUM_SERVER_CMD} ${SELENIUM_SERVER_ARG} -log
	    ${RESULT_DIR_ABSOLUTE}/${testSuiteName}.${testRole}.${browser}.test.log
	    -htmlsuite ${BROWSER_STR} ${ZANATA_URL}  ${suiteFile}
	    ${RESULT_DIR_ABSOLUTE}/${testSuiteName}.${testRole}.${browser}.html)
    ENDFOREACH()
ENDMACRO()


# Generate test suite for role
MACRO(GENERATE_TEST_FOR_ROLE testSuiteDir testSuiteName testRole)
    IF(NOT "${${testRole}_SISO}" STREQUAL "")
	EXECUTE_PROCESS(COMMAND git-ls-files
	    COMMAND grep -e "\\.html"
	    COMMAND xargs -I X echo -n "${testSuiteDir}/X;"
	    COMMAND sed -e "s/;$//g"
	    WORKING_DIRECTORY "${testSuiteDir}"
	    OUTPUT_VARIABLE _srcFiles
	    OUTPUT_STRIP_TRAILING_WHITESPACE
	    )

	SET(_suiteFile  "${testSuiteDir}/${${testRole}_SISO}-${testSuiteName}.html")
	MATH(EXPR _si "${${testRole}_SISO}-1")
	SET(_suiteFile_si "${testSuiteDir}/${_si}-${testSuiteName}.html")
	SET(_suiteFiles ${_suiteFile} ${_suiteFile_si})

	SET(_caseFiles  "${testSuiteDir}/SignIn${testRole}.html"
	    "${testSuiteDir}/SignOut.html"
	    )

	#MESSAGE("_srcFiles=${_srcFiles}")

	# Generate test suite
	ADD_CUSTOM_COMMAND(OUTPUT ${_suiteFiles}
	    COMMAND ${CMAKE_SOURCE_DIR}/scripts/generate_test_suite.sh
	    ${testRole} ${testSuiteDir} ${testSuiteName}
	    ${SERVER_BASE} "${SERVER_PATH}"
	    ${${testRole}_USER} ${${testRole}_PASSWD} ${${testRole}_SISO}
	    ${AUTH_METHOD} ${LOGIN_FIELD_ID} ${PASSWORD_FIELD_ID}
	    DEPENDS ${_srcFiles} ${testSuiteDir}/HomePage.html
	    COMMENT "Generate test suite ${testSuiteName} for ${testRole}"
	    VERBATIM
	    )

	ADD_CUSTOM_TARGET(generate_test_suite_${testSuiteName}_${testRole}  ALL
	    DEPENDS ${_suiteFiles} ${_caseFiles}
	    )
	GENERATE_TEST_FOREACH_BROWSER(
	    ${testSuiteDir} ${testSuiteName} ${testRole} ${_suiteFile})

    ENDIF(NOT "${${testRole}_SISO}" STREQUAL "")
ENDMACRO(GENERATE_TEST_FOR_ROLE testSuiteDir testSuiteName testRole)


# Generate test for each role
MACRO(GENERATE_TEST_FOREACH_ROLE testSuiteDir testSuiteName)
    IF(EXISTS "${testSuiteDir}/TEST_Prelogin")
	SET(_testRoles ${TEST_ROLES} Prelogin)
    ELSE()
	SET(_testRoles ${TEST_ROLES})
    ENDIF()

    SET(_TITLE "Home Page")
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/templates/HomePage.html.in
	${testSuiteDir}/HomePage.html @ONLY)
    FOREACH(_testRole ${_testRoles})
	IF(NOT EXISTS "${testSuiteDir}/NO_${_testRole}" )
	    GENERATE_TEST_FOR_ROLE("${testSuiteDir}" "${testSuiteName}"	"${_testRole}")
	ENDIF(NOT EXISTS "${testSuiteDir}/NO_${_testRole}" )
    ENDFOREACH()
ENDMACRO(GENERATE_TEST_FOREACH_ROLE testSuiteDir testSuiteName)

#===================================================================
# Generate test suites.

## General tests
MESSAGE("Generating General Test Suites:")
FOREACH(testSuiteRaw ${TEST_SUITES_RAW})
    GET_FILENAME_COMPONENT(testSuitePath ${testSuiteRaw} PATH)
    GET_FILENAME_COMPONENT(testSuiteNameOrig ${testSuiteRaw} NAME_WE)
    STRING(REGEX REPLACE "^0-" "" testSuiteName ${testSuiteNameOrig})

    # Make test rules.
    MESSAGE("  Name=${testSuiteName} Path=${testSuitePath} ")
    GENERATE_TEST_FOREACH_ROLE(${testSuitePath} ${testSuiteName})
ENDFOREACH(testSuiteRaw ${TEST_SUITES_RAW})



### Privilege tests
#EXECUTE_PROCESS(COMMAND ${CMAKE_SOURCE_DIR}/scripts/generate_privilege_test_suite.sh ${PRIVILEGE_TEST_ROOT_ABSOLUTE})
#GENERATE_TEST_FOREACH_BROWSER(${PRESIGNIN_TEST_SUITE_NAME} PRE_LOGIN
#    ${PRIVILEGE_TEST_ROOT_ABSOLUTE}/${PRESIGNIN_TEST_SUITE} )
#GENERATE_TEST_FOREACH_BROWSER(${NORMAL_TEST_SUITE_NAME} NORMAL
#    ${PRIVILEGE_TEST_ROOT_ABSOLUTE}/${NORMAL_TEST_SUITE_SISO} )

#IF(NOT EXISTS ${RESULT_DIR_ABSOLUTE})
#    file(MAKE_DIRECTORY ${RESULT_DIR_ABSOLUTE})
#ENDIF()

