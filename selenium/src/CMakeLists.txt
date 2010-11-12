#===================================================================
# Test generating macros

MACRO(ADD_OUTPUT_FOR_BROWSERS testSuiteName testRole suiteFile)
    FOREACH(browser ${BROWSERS_TO_TEST})
	SET(BROWSER_STR "*${browser}\\ ${${browser}_BIN}")
	ADD_TEST("${testSuiteName}.${testRole}.${browser}"
	    ${SELENIUM_SERVER_CMD} ${SELENIUM_SERVER_ARG} -log
	    ${RESULT_DIR_ABSOLUTE}/${testSuiteName}.${testRole}.${browser}.test.log
	    -htmlsuite ${BROWSER_STR} ${FLIES_URL}  ${suiteFile}
	    ${RESULT_DIR_ABSOLUTE}/${testSuiteName}.${testRole}.${browser}.html)
    ENDFOREACH()
ENDMACRO()

MACRO(GENERATE_TEST_SUITE testRole testSuitePath testSuiteName siOut
	siSoOut testRoot)
    SET(SI_PATTERN_MATCH "</b></td></tr>")
    IF(testRole STREQUAL "ADMIN")
	SET(SIGN_IN_FILE "SignInAdmin.html")
    ELSE(testRole STREQUAL "ADMIN")
	SET(SIGN_IN_FILE "SignInNormal.html")
    ENDIF(testRole STREQUAL "ADMIN")
    SET(SIGN_OUT_FILE "SignOut.html")


    SET(SI_PATTERN_REPLACE
	"${SI_PATTERN_MATCH}\n<tr><td><a href=\"${SIGN_IN_FILE}\">${testRole} Sign In</a></td></tr>")
    EXECUTE_PROCESS(COMMAND ln -sf ${FUNCTIONS_DIR_ABSOLUTE}/${SIGN_IN_FILE}
	${testSuitePath}/${SIGN_IN_FILE})

    SET(SO_PATTERN_MATCH "</tbody>")
    SET(SO_PATTERN_REPLACE
	"<tr><td><a href=\"${SIGN_OUT_FILE}\">Sign Out</a></td></tr>\n${SO_PATTERN_MATCH}")
    EXECUTE_PROCESS(COMMAND ln -sf ${FUNCTIONS_DIR_ABSOLUTE}/${SIGN_OUT_FILE}
	${testSuitePath}/${SIGN_OUT_FILE})

    ### Write Selenium test files
    FILE(READ ${testSuitePath}/0-${testSuiteName}.html _testSuiteContent)
    STRING(REGEX REPLACE "${SI_PATTERN_MATCH}" "${SI_PATTERN_REPLACE}"
	_testSuiteContent "${_testSuiteContent}")
    FILE(WRITE ${testSuitePath}/${siOut} "${_testSuiteContent}")

    STRING(REGEX REPLACE ${SO_PATTERN_MATCH} ${SO_PATTERN_REPLACE}
	_testSuiteContent "${_testSuiteContent}")
    FILE(WRITE ${testSuitePath}/${siSoOut} "${_testSuiteContent}")
ENDMACRO(GENERATE_TEST_SUITE testRole testSuitePath=$2 testSuiteName siOut
        siSoOut testRoot)


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
		GENERATE_TEST_SUITE(${testRole} ${testSuitePath}
		    ${testSuiteName} ${SI_TEST_TARGET} ${SISO_TEST_TARGET}
		    ${TEST_ROOT_ABSOLUTE})
	    ENDIF()
	    ADD_OUTPUT_FOR_BROWSERS(${testSuiteName} "${testRole}" ${suiteFile} )
	ENDIF()
    ENDFOREACH()
ENDMACRO(ADD_OUTPUT_AND_TEST testRole testSuitePath testSuiteName)

#===================================================================
# Generate test suites.
MESSAGE("TEST_ROOT_ABSOLUTE=${TEST_ROOT_ABSOLUTE}")
FIND_FILES_IN_DIR(TEST_SUITES_RAW  "0-*.html" "${TEST_ROOT_ABSOLUTE}")

MESSAGE("TEST_SUITES_RAW=${TEST_SUITES_RAW}")

# Flow control extension
SET(SELENIUM_EXTENSION "${CMAKE_SOURCE_DIR}/selenium/dependencies/goto_sel08.js")

LIST(APPEND SELENIUM_SERVER_ARG -port ${SELENIUM_SERVER_PORT} -debug
    -userExtensions ${SELENIUM_EXTENSION})

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

### Privilege tests
#EXECUTE_PROCESS(COMMAND ${CMAKE_SOURCE_DIR}/scripts/generate_privilege_test_suite.sh ${PRIVILEGE_TEST_ROOT_ABSOLUTE})
#ADD_OUTPUT_FOR_BROWSERS(${PRESIGNIN_TEST_SUITE_NAME} PRE_LOGIN
#    ${PRIVILEGE_TEST_ROOT_ABSOLUTE}/${PRESIGNIN_TEST_SUITE} )
#ADD_OUTPUT_FOR_BROWSERS(${NORMAL_TEST_SUITE_NAME} NORMAL
#    ${PRIVILEGE_TEST_ROOT_ABSOLUTE}/${NORMAL_TEST_SUITE_SISO} )

#IF(NOT EXISTS ${RESULT_DIR_ABSOLUTE})
#    file(MAKE_DIRECTORY ${RESULT_DIR_ABSOLUTE})
#ENDIF()

