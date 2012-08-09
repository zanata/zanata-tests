#===================================================================
# Initial server setup

SET(FILL_SERVER_CONFIGURATION_FIELDS "")
MACRO(APPEND_FILL_SERVER_CONFIGURATION field value)
    SELENIUM_TYPE_ON_FIELD(_snipplet
	"css=input[id*=\"${field}\"]" "${value}")
    IF(FILL_SERVER_CONFIGURATION_FIELDS)
	SET(FILL_SERVER_CONFIGURATION_FIELDS
	    "${FILL_SERVER_CONFIGURATION_FIELDS}\n${_snipplet}")
    ELSE(FILL_SERVER_CONFIGURATION_FIELDS)
	SET(FILL_SERVER_CONFIGURATION_FIELDS
	    "${_snipplet}")
    ENDIF(FILL_SERVER_CONFIGURATION_FIELDS)
ENDMACRO(APPEND_FILL_SERVER_CONFIGURATION field value)

APPEND_FILL_SERVER_CONFIGURATION("urlField" "\${SERVER_BASE}")
APPEND_FILL_SERVER_CONFIGURATION("registerField" "\${SERVER_BASE}/register")
APPEND_FILL_SERVER_CONFIGURATION("emailDomainField" "redhat.com")
APPEND_FILL_SERVER_CONFIGURATION("adminEmailField" "admin@\${SERVER_HOST}")
APPEND_FILL_SERVER_CONFIGURATION("fromEmailField" "zanata@\${SERVER_HOST}")
IF(SERVER_HOST MATCHES "zanata-master")
    APPEND_FILL_SERVER_CONFIGURATION("piwikUrlField" "hiro.bne.redhat.com/piwik")
    APPEND_FILL_SERVER_CONFIGURATION("piwikIdSiteField" "11")
ENDIF(SERVER_HOST MATCHES "zanata-master")

CONFIGURE_FILE(ServerConfiguration.html.in
    ${CMAKE_CURRENT_SOURCE_DIR}/ServerConfiguration.html @ONLY)

MACRO(GENERATE_ADD_LANGUAGE_SNIPPET var lang)
    GENERATE_SELENIUM_COMMAND(_header1
	"storeElementPresent"
	"ui=adminPages::manageLangTableRow(lang=${lang})"
	"langExists")
    GENERATE_SELENIUM_COMMAND(_header2
	"gotoIf"
	\\\${langExists}
	"End_${lang}")
    GENERATE_SELENIUM_COMMAND(_add_lang "rollup" "add_new_language"
	"lang=${lang}")
    GENERATE_SELENIUM_COMMAND(_footer "label" "End_${lang}" "")

    SET(${var} "${_header1}\n${_header2}\n${_add_lang}\n${_footer}\n")
ENDMACRO(GENERATE_ADD_LANGUAGE_SNIPPET)

SET(ADD_LANGS_SNIPPET "")
FOREACH(_lang ${ENABLED_LANGUAGES})
    GENERATE_ADD_LANGUAGE_SNIPPET(_lStr "${_lang}")
    SET(ADD_LANGS_SNIPPET "${ADD_LANGS_SNIPPET}${_lStr}")
ENDFOREACH(_lang ${ENABLED_LANGUAGE})

CONFIGURE_FILE(ManageLanguages.html.in
    ${CMAKE_CURRENT_SOURCE_DIR}/ManageLanguages.html @ONLY)

SET(SIGN_IN_USER "${ADMIN_USER}")
SET(SIGN_IN_PASSWD "${ADMIN_PASSWD}")

CONFIGURE_FILE(../functions/SignIn.html.in
    ${CMAKE_CURRENT_SOURCE_DIR}/SignInAdmin.html @ONLY)

ADD_CUSTOM_TARGET(initial_setup
    ${SELENIUM_SERVER_CMD} ${SELENIUM_SERVER_ARG}
    -port ${SELENIUM_SERVER_PORT}
    -log ${RESULT_DIR_ABSOLUTE}/initial_setup.test.log
    -htmlsuite "*firefox\ ${firefox_BIN}" ${ZANATA_URL}
    ${CMAKE_CURRENT_SOURCE_DIR}/00-InitSetup.html
    ${RESULT_DIR_ABSOLUTE}/initial_setup.html
    VERBATIM
    )


