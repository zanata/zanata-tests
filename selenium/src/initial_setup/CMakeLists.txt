#===================================================================
# Initial server setup


#-------------------------------------------------------------------
# Snippet to admin page
#
SET(_VISIT_ADMIN_PAGE "")
SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "storeElementPresent" "link=More" "menuSystemExist")
SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "gotoIf" "! #{menuSystemExist}" "inAdminPage")
# Post 1.7
SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "mouseOver" "link=More" "")

SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "clickAndWait" "id=Administration" "")

SELENIUM_APPEND(VISIT_ADMIN_PAGE
    "label" "inAdminPage" "")
# End Post 1.7
STRING(REPLACE "#{" "\${" VISIT_ADMIN_PAGE
    "${VISIT_ADMIN_PAGE}")

#-------------------------------------------------------------------
# Server configuration
#
SET(FILL_SERVER_CONFIGURATION_FIELDS "")
MACRO(APPEND_FILL_SERVER_CONFIGURATION field value)
    SELENIUM_APPEND(FILL_SERVER_CONFIGURATION_FIELDS
	"rollup" "click_type" "loc=css=input[id*=\"${field}\"], value=${value}")
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

#-------------------------------------------------------------------
# Manage Languages
#
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

SET(LANG_SNIPPETS "")
FOREACH(_lang ${LANGUAGES_ENABLE})
    APPEND_LANGUAGE_SNIPPET(LANG_SNIPPETS "${_lang}")
ENDFOREACH(_lang ${LANGUAGES_ENABLE})

STRING(REPLACE "#{" "\${" LANG_SNIPPETS
    "${LANG_SNIPPETS}")
CONFIGURE_FILE(ManageLanguages.html.in
    ${CMAKE_CURRENT_SOURCE_DIR}/ManageLanguages.html @ONLY)

#-------------------------------------------------------------------
# Language to Join
#

SET(LANGS_TO_JOIN "")
FOREACH(_lang ${LANGUAGES_JOIN})
    SELENIUM_APPEND(LANGS_TO_JOIN
	"rollup" "join_language" "lang=${_lang}")
    SELENIUM_APPEND(LANGS_TO_JOIN
	"gotoIf" "! #{_isElementPresent}" "joined_${_lang}")
    SELENIUM_APPEND(LANGS_TO_JOIN
	"click" "id=Language_team_member_toggle_form:Join" "")
    SELENIUM_APPEND(LANGS_TO_JOIN
	"label" "joined_${_lang}" "")
ENDFOREACH(_lang ${LANGUAGES_JOIN})

STRING(REPLACE "#{" "\${" LANGS_TO_JOIN
    "${LANGS_TO_JOIN}")
CONFIGURE_FILE(JoinLanguages.html.in
    ${CMAKE_CURRENT_SOURCE_DIR}/JoinLanguages.html @ONLY)

#-------------------------------------------------------------------
# Sign in as Admin
#

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


