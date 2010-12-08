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

#MACRO(GENERATE_TEST_SUITE testRole testSuitePath testSuiteName siOut
#	siSoOut testRoot)
#    SET(SI_PATTERN_MATCH "</b></td></tr>")
#    IF(testRole STREQUAL "ADMIN")
#	SET(SIGN_IN_FILE "SignInAdmin.html")
#    ELSE(testRole STREQUAL "ADMIN")
#	SET(SIGN_IN_FILE "SignInNormal.html")
#    ENDIF(testRole STREQUAL "ADMIN")
#    SET(SIGN_OUT_FILE "SignOut.html")
#
#
#    SET(SI_PATTERN_REPLACE
#	"${SI_PATTERN_MATCH}\n<tr><td><a href=\"${SIGN_IN_FILE}\">${testRole} Sign In</a></td></tr>")
#    EXECUTE_PROCESS(COMMAND ln -sf ${FUNCTIONS_DIR_ABSOLUTE}/${SIGN_IN_FILE}
#	${testSuitePath}/${SIGN_IN_FILE})
#
#    SET(SO_PATTERN_MATCH "</tbody>")
#    SET(SO_PATTERN_REPLACE
#	"<tr><td><a href=\"${SIGN_OUT_FILE}\">Sign Out</a></td></tr>\n${SO_PATTERN_MATCH}")
#    EXECUTE_PROCESS(COMMAND ln -sf ${FUNCTIONS_DIR_ABSOLUTE}/${SIGN_OUT_FILE}
#	${testSuitePath}/${SIGN_OUT_FILE})
#
#    ### Write Selenium test files
#    FILE(READ ${testSuitePath}/0-${testSuiteName}.html _testSuiteContent)
#    STRING(REGEX REPLACE "${SI_PATTERN_MATCH}" "${SI_PATTERN_REPLACE}"
#	_testSuiteContent "${_testSuiteContent}")
#    FILE(WRITE ${testSuitePath}/${siOut} "${_testSuiteContent}")
#
#    STRING(REGEX REPLACE ${SO_PATTERN_MATCH} ${SO_PATTERN_REPLACE}
#	_testSuiteContent "${_testSuiteContent}")
#    FILE(WRITE ${testSuitePath}/${siSoOut} "${_testSuiteContent}")
#ENDMACRO(GENERATE_TEST_SUITE testRole testSuitePath=$2 testSuiteName siOut
#        siSoOut testRoot)
#

MACRO(ADD_OUTPUT_AND_TEST testSuiteDir testSuiteName)
    IF (EXISTS "${testSuiteDir}/TEST_Prelogin")
	SET(_testRoles ${TEST_ROLES} Prelogin)
    ELSE()
	SET(_testRoles ${TEST_ROLES})
    ENDIF()
    MESSAGE("testPath=${testSuiteDir}")
    FOREACH(_testRole ${_testRoles})
	IF(NOT EXISTS "${testSuiteDir}/NO_${_testRole}" )
	    IF( ${_testRole} STREQUAL "Prelogin" )
		SET(_suiteFile ${testSuiteDir}/0-${testSuiteName}.html)
	    ELSE()
		IF( ${_testRole} STREQUAL "Admin" )
		    SET(_suiteFile ${testSuiteDir}/2-${testSuiteName}.html)
		    SET(_suiteFiles ${testSuiteDir}/1-${testSuiteName}.html
			${_suiteFile})
		ELSEIF( ${_testRole} STREQUAL "Prjmant" )
		    SET(_suiteFile ${testSuiteDir}/4-${testSuiteName}.html)
		    SET(_suiteFiles ${testSuiteDir}/3-${testSuiteName}.html
			${_suiteFile})
		ELSEIF( ${_testRole} STREQUAL "Trans" )
		    SET(_suiteFile ${testSuiteDir}/6-${testSuiteName}.html)
		    SET(_suiteFiles ${testSuiteDir}/5-${testSuiteName}.html
			${_suiteFile})
		ELSEIF( ${_testRole} STREQUAL "Login" )
		    SET(_suiteFile ${testSuiteDir}/8-${testSuiteName}.html)
		    SET(_suiteFiles ${testSuiteDir}/7-${testSuiteName}.html
			${_suiteFile})
		ENDIF()
		SET(_generateTestCases ${testSuiteDir}/SignIn${_testRole}.html
		    ${testSuiteDir}/SignOut.html
		    ${testSuiteDir}/HomePage.html )

		# Generate test suite
		ADD_CUSTOM_COMMAND(OUTPUT ${_suiteFiles} ${_generateTestCases}
		    COMMAND ${CMAKE_SOURCE_DIR}/scripts/generate_test_suite.sh
		    ${CMAKE_SOURCE_DIR}/test.cfg ${_testRole} ${testSuiteDir} ${testSuiteName}
		    COMMENT "Generate test suite ${testSuiteName} for ${_testRole}"
		    )

		ADD_CUSTOM_TARGET(generate_test_suite_${testSuiteName}_${_testRole}  ALL
		    DEPENDS ${_suiteFiles} ${_generateTestCases}
		    )
	    ENDIF()
	    ADD_OUTPUT_FOR_BROWSERS(${testSuiteName} ${_testRole} ${_suiteFile} )
	ENDIF()
    ENDFOREACH()
ENDMACRO(ADD_OUTPUT_AND_TEST testSuiteDir testSuiteName)

#===================================================================
# Generate test suites.
MESSAGE("TEST_ROOT_ABSOLUTE=${TEST_ROOT_ABSOLUTE}")
FIND_FILES_IN_DIR(TEST_SUITES_RAW  "0-*.html" "${TEST_ROOT_ABSOLUTE}")

MESSAGE("TEST_SUITES_RAW=${TEST_SUITES_RAW}")

# Flow control extension
SET(SELENIUM_EXTENSION
    "${CMAKE_SOURCE_DIR}/selenium/dependencies/user-extensions.js")

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

