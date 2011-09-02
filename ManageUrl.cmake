# - Collection of Url utility macros.
#
# Includes:
#   ManageString
#
# Defines the following functions:
#   GET_URL_COMPONENT(var url
#     SCHEME | USERNAME | PASSWORD | HOSTNAME | PORT | PATH | QUERY |
#     FRAGMENT | USERINFO | AUTHORITY )
#   - Get a specific component of a full URL.
#
#     The URL syntax is:
#     scheme://username:password@domain:port/path?query#fragment
#
#     Set var to be the value of specified part:
#     Note that: USERINFO means USERNAME:PASSWORD
#     AUTHORITY means USERINFO@HOSTNAME:PORT
#     * Parameters:
#       + var: A variable that stores the result.
#       + str: A string.
#       + NOUNQUOTE: (Optional) do not remove the double quote mark around the string.
#

IF(NOT DEFINED _MANAGE_URL_CMAKE_)
    SET(_MANAGE_URL_CMAKE_ "DEFINED")
    INCLUDE(ManageString)

    FUNCTION(GET_AUTHORITY_COMPONENT var authority component)
	SET(_USERINFO "")
	SET(_USERNAME "")
	SET(_PASSWORD "")
	SET(_HOSTNAME "")
	SET(_PORT "")
	IF("${authority}" MATCHES "@")
	    STRING(REGEX REPLACE "(.*)@(.*)" "\\1" _USERINFO "${authorithy}")
	    STRING(REGEX REPLACE "(.*)@(.*)" "\\2" _HOSTPORT "${authorithy}")

	    ## Split USERINFO
	    IF("${_USERINFO}" MATCHES ":")
		STRING(REGEX REPLACE "(.*):(.*)" "\\1" _USERNAME "${_USERINFO}")
		STRING(REGEX REPLACE "(.*):(.*)" "\\2" _PASSWORD "${_USERINFO}")
	    ELSE("${_USERINFO}" MATCHES ":")
		SET(_USERNAME "${_USERINFO}")
	    ENDIF("${_USERINFO}" MATCHES ":")
	ELSE("${authority}" MATCHES "@")
	    SET(_HOSTPORT "${authority}")
	ENDIF("${authority}" MATCHES "@")

	## Split host port
	IF("${_HOSTPORT}" MATCHES ":")
	    STRING(REGEX REPLACE "(.*):(.*)" "\\1" _HOSTNAME "${_HOSTPORT}")
	    STRING(REGEX REPLACE "(.*):(.*)" "\\2" _PORT "${_HOSTPORT}")
	ELSE("${_HOSTPORT}" MATCHES ":")
	    SET(_HOSTNAME "${_HOSTPORT}")
	ENDIF("${_HOSTPORT}" MATCHES ":")
	MESSAGE("authority=${authority}")
	MESSAGE("_HOSTPORT=${_HOSTPORT}")
	MESSAGE("_HOSTNAME=${_HOSTNAME}")
	MESSAGE("_PORT=${_PORT}")

	SET(${var} "${_${component}}" PARENT_SCOPE)
    ENDFUNCTION(GET_AUTHORITY_COMPONENT var url component)

    FUNCTION(GET_URL_OPTIONAL_COMPONENT var optional component)
	SET(_PATH "")
	SET(_QUERY "")
	SET(_FRAGMENT "")

	IF("${optional}" MATCHES "#.*$")
	    STRING(REGEX REPLACE "(.*)#(.*)" "\\2" _FRAGMENT "${optional}")
	    STRING(REGEX REPLACE "(.*)#(.*)" "\\1" _OPT_WO_F "${optional}")
	ELSE("${optional}" MATCHES "#.*$")
	    SET(_OPT_WO_F "${optional}")
	ENDIF("${optional}" MATCHES "#.*$")
	#MESSAGE("_OPT_WO_F=${_OPT_WO_F}")

	IF("${_OPT_WO_F}" MATCHES "[?]")
	    STRING(REGEX REPLACE "(.*)[?](.*)" "\\2" _QUERY "${_OPT_WO_F}")
	    STRING(REGEX REPLACE "(.*)[?](.*)" "\\1" _PATH "${_OPT_WO_F}")
	    #MESSAGE("_QUERY=${_QUERY}")
	ELSE("${_OPT_WO_F}" MATCHES "[?]")
	    SET(_PATH "${_OPT_WO_F}")
	ENDIF("${_OPT_WO_F}" MATCHES "[?]")
	#MESSAGE("_PATH=${_PATH}")

	SET(${var} "${_${component}}" PARENT_SCOPE)
    ENDFUNCTION(GET_URL_OPTIONAL_COMPONENT var optional component)

    FUNCTION(GET_URL_COMPONENT var url component)
	SET(_ret "")

	# 1st part is scheme
	# 2nd part is "//"
	# 3rd part is authority
	# 4th part is optional (path, query, and fragment)
	IF(component STREQUAL "SCHEME")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\1" _ret "${url}")

        ##   authority
	ELSEIF(component STREQUAL "AUTHORITY")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\3" _ret "${url}")
	ELSEIF(component STREQUAL "USERINFO")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\3" _authority "${url}")
	    GET_AUTHORITY_COMPONENT(_ret "${_authority}" "${component}")
	ELSEIF(component STREQUAL "USERNAME")
	    STRING(REGEX REPLACE
	       "^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\3" _authority "${url}")
	    GET_AUTHORITY_COMPONENT(_ret "${_authority}" "${component}")
	ELSEIF(component STREQUAL "PASSWORD")
	    STRING(REGEX REPLACE
	       "^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\3" _authority "${url}")
	    GET_AUTHORITY_COMPONENT(_ret "${_authority}" "${component}")
	ELSEIF(component STREQUAL "HOSTNAME")
	    STRING(REGEX REPLACE
	       "^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\3" _authority "${url}")
	    GET_AUTHORITY_COMPONENT(_ret "${_authority}" "${component}")
	ELSEIF(component STREQUAL "PORT")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\3" _authority "${url}")
	    GET_AUTHORITY_COMPONENT(_ret "${_authority}" "${component}")

	##   Optional
	ELSEIF(component STREQUAL "PATH")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\4" _optional "${url}")
	    GET_URL_OPTIONAL_COMPONENT(_ret "${_optional}" "${component}")
	ELSEIF(component STREQUAL "QUERY")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\4" _optional "${url}")
	    GET_URL_OPTIONAL_COMPONENT(_ret "${_optional}" "${component}")
	ELSEIF(component STREQUAL "FRAGMENT")
	    STRING(REGEX REPLACE
		"^([^:]*):(//)?([^/#?]*)(.*)$"
		"\\4" _optional "${url}")
	    GET_URL_OPTIONAL_COMPONENT(_ret "${_optional}" "${component}")
	ENDIF(component STREQUAL "SCHEME")
	SET(${var} "${_ret}" PARENT_SCOPE)
    ENDFUNCTION(GET_URL_COMPONENT var url component)
ENDIF(NOT DEFINED _MANAGE_URL_CMAKE_)

