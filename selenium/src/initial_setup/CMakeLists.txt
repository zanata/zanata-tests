#===================================================================
# Initial server setup


#-------------------------------------------------------------------
# Snippet to admin page
#
SET(_VISIT_ADMIN_PAGE "")
SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "storeElementPresent" "link=System" "menuSystemExist")
SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "gotoIf" "! #{menuSystemExist}" "inAdminPage")
# Post 1.7
SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "mouseOver" "link=System" "")

SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "clickAndWait" "id=Administration" "")

SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "label" "inAdminPage" "")
# End Post 1.7
STRING(REPLACE "#{" "\${" VISIT_ADMIN_PAGE
    "${VISIT_ADMIN_PAGE}")

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

APPEND_FILL_SERVER_CONFIGURATION("urlField" "#{SERVER_BASE}")
APPEND_FILL_SERVER_CONFIGURATION("registerField" "#{SERVER_BASE}/register")
APPEND_FILL_SERVER_CONFIGURATION("emailDomainField" "redhat.com")
APPEND_FILL_SERVER_CONFIGURATION("adminEmailField" "admin@#{SERVER_HOST}")
APPEND_FILL_SERVER_CONFIGURATION("fromEmailField" "zanata@#{SERVER_HOST}")
IF(SERVER_HOST MATCHES "zanata-master")
    APPEND_FILL_SERVER_CONFIGURATION("piwikUrlField" "hiro.bne.redhat.com/piwik")
    APPEND_FILL_SERVER_CONFIGURATION("piwikIdSiteField" "11")
ENDIF(SERVER_HOST MATCHES "zanata-master")

STRING(REPLACE "#{" "\${" FILL_SERVER_CONFIGURATION_FIELDS
    "${FILL_SERVER_CONFIGURATION_FIELDS}")

CONFIGURE_FILE(ServerConfiguration.html.in
    ${CMAKE_CURRENT_SOURCE_DIR}/ServerConfiguration.html @ONLY)

MACRO(APPEND_LANGUAGE_SNIPPET var lang)
    SELENIUM_APPEND(${var}
	"storeElementPresent"
	"ui=adminPages::manageLangTableRow(lang=${lang})"
	"langExists")
    SELENIUM_APPEND(${var}
	"gotoIf"
	"#{langExists}"
	"End_${lang}")
    SELENIUM_APPEND(${var} "rollup" "add_new_language"
	"lang=${lang}")
    SELENIUM_APPEND(${var} "label" "End_${lang}" "")
ENDMACRO(APPEND_LANGUAGE_SNIPPET var lang)

SET(_LANG_SNIPPETS "")
FOREACH(_lang ${ENABLED_LANGUAGES})
    APPEND_LANGUAGE_SNIPPET(_LANG_SNIPPETS "${_lang}")
ENDFOREACH(_lang ${ENABLED_LANGUAGE})
#MESSAGE("_LANG_SNIPPETS=${_LANG_SNIPPETS}")

STRING(REPLACE "#{" "\${" LANG_SNIPPETS
    "${_LANG_SNIPPETS}")
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


