# - Collection of String utility macros.
# Defines the following macros:
#   STRING_TRIM(var str [NOUNQUOTED])
#     - Trim a string by removing the leading and trailing spaces,
#       just like STRING(STRIP ...) in CMake 2.6 and later.
#       This macro is needed as CMake 2.4 does not support STRING(STRIP ..)
#       * Parameters:
#          var: A variable that stores the result.
#          str: A string.
#          UNQUOTED: (Optional) remove the double quote mark around the string.
#
IF(NOT DEFINED _MANAGE_STRING_CMAKE_)
    SET(_MANAGE_STRING_CMAKE_ "DEFINED")

    MACRO(STRING_TRIM var str)
	SET(${var} "")
	IF (NOT "${ARGN}" STREQUAL "NOUNQUOTED")
	    # Need not trim a quoted string.
	    STRING_UNQUOTED(_var str)
	    IF(NOT _var STREQUAL "")
		# String is quoted
		SET(${var} "${_var}")
	    ENDIF(NOT _var STREQUAL "")
	ENDIF(NOT "${ARGN}" STREQUAL "NOUNQUOTED")

	IF(${var} STREQUAL "")
	    SET(_var_1 "+${str}+")
	    STRING(REPLACE  "^[+][ \t\r\n]*" "" _var_2 "${_var_1}" )
	    STRING(REPLACE  "[ \t\r\n]*[+]$" "" ${var} "${_var_2}" )
	ENDIF(${var} STREQUAL "")
    ENDMACRO(STRING_TRIM var str)

    MACRO(STRING_UNQUOTED var str)
	IF ("${ARGN}" STREQUAL "")
	    SET(_quoteChars "\"" "'")
	ELSE ("${ARGN}" STREQUAL "")
	    SET(_quoteChars ${ARGN})
	ENDIF ("${ARGN}" STREQUAL "")

	SET(_var "")
	FOREACH(_qch ${_quoteChars})
	    MESSAGE("_var=${_var} _qch=${_qch}")
	    IF(_var STREQUAL "")
		STRING(REPLACE "^[ \t\r\n]*${_qch}\(.*[^\\]*\)${_qch}[ \t\r\n]*$" "\\1" _var ${str})
	    ENDIF(_var STREQUAL "")
	ENDFOREACH(_qch ${_quoteChars})
	SET(${var} "${_var}")
    ENDMACRO(STRING_UNQUOTED var str)

    #    MACRO(STRING_ESCAPE_SEMICOLON var str)
    #	STRING(REGEX REPLACE ";" "\\\\;" ${var} "${str}")
    #ENDMACRO(STRING_ESCAPE_SEMICOLON var str)

    MACRO(STRING_SPLIT var delimiter str)
	SET(_max_tokens "")
	FOREACH(_arg ${ARGN})
	    IF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_NOESCAPE_SEMICOLON "NOESCAPE_SEMICOLON")
	    ELSE(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
		SET(_max_tokens ${_arg})
	    ENDIF(${_arg} STREQUAL "NOESCAPE_SEMICOLON")
	ENDFOREACH(_arg)

	IF(NOT _max_tokens)
	    SET(_max_tokens -1)
	ENDIF(NOT _max_tokens)

	# ';' and '\' are tricky, need to be encoded.
	# '\' => '#B'
	# '#' => '#H'
	STRING(REGEX REPLACE "#" "#H" _str "${str}")
	STRING(REGEX REPLACE "#" "#H" _delimiter "${delimiter}")

	STRING(REGEX REPLACE "\\\\" "#B" _str "${_str}")

	IF(NOT _NOESCAPE_SEMICOLON STREQUAL "")
	    # ';' => '#S'
	    STRING(REGEX REPLACE ";" "#S" _str "${_str}")
	    STRING(REGEX REPLACE ";" "#S" _delimiter "${_delimiter}")
	ENDIF(NOT _NOESCAPE_SEMICOLON STREQUAL "")

	SET(_str_list "")
	SET(_token_count 0)
	STRING(LENGTH "${_delimiter}" _de_len)

	WHILE(NOT _token_count EQUAL _max_tokens)
	    #MESSAGE("_token_count=${_token_count} _max_tokens=${_max_tokens} _str=${_str}")
	    MATH(EXPR _token_count ${_token_count}+1)
	    IF(_token_count EQUAL _max_tokens)
		# Last token, no need splitting
		SET(_str_list ${_str_list} "${_str}")
	    ELSE(_token_count EQUAL _max_tokens)
		# in case encoded characters are delimiters
		STRING(LENGTH "${_str}" _str_len)
		SET(_index 0)
		#MESSAGE("_str_len=${_str_len}")
		SET(_token "")
		MATH(EXPR _str_end ${_str_len}-${_de_len}+1)
		SET(_bound "k")
		WHILE(_index LESS _str_end)
		    STRING(SUBSTRING "${_str}" ${_index} ${_de_len} _str_cursor)
		    #MESSAGE("_index=${_index} _str_cursor=${_str_cursor} _delimiter=${_delimiter} _de_len=${_de_len}")
		    IF(_str_cursor STREQUAL _delimiter)
			# Get the token
			STRING(SUBSTRING "${_str}" 0 ${_index} _token)
			# Get the rest
			MATH(EXPR _rest_index ${_index}+${_de_len})
			MATH(EXPR _rest_len ${_str_len}-${_index}-${_de_len})
			STRING(SUBSTRING "${_str}" ${_rest_index} ${_rest_len} _str_remain)
			SET(_index ${_str_end})
		    ELSE(_str_cursor STREQUAL _delimiter)
			MATH(EXPR _index ${_index}+1)
		    ENDIF(_str_cursor STREQUAL _delimiter)
		ENDWHILE(_index LESS _str_end)

		#MESSAGE("_token=${_token} _str_remain=${_str_remain}")

		IF(_token STREQUAL "")
		    # Meaning: end of string
		    SET(_str_list ${_str_list} "${_str}")
		    SET(_max_tokens ${_token_count})
		ELSE(_token STREQUAL "")
		    SET(_str_list ${_str_list} "${_token}")
		    SET(_str "${_str_remain}")
		ENDIF(_token STREQUAL "")
	    ENDIF(_token_count EQUAL _max_tokens)
	    #MESSAGE("_token_count=${_token_count} _max_tokens=${_max_tokens} _str=${_str}")
	ENDWHILE(NOT _token_count EQUAL _max_tokens)


	# Unencoding
	STRING(REGEX REPLACE "#B" "\\\\" _str_list "${_str_list}")
	STRING(REGEX REPLACE "#H" "#" _str_list "${_str_list}")

	IF(NOT _NOESCAPE_SEMICOLON STREQUAL "")
	    # ';' => '#S'
	    STRING(REGEX REPLACE "#S" "\\\\;" ${var} "${_str_list}")
	ELSE(NOT _NOESCAPE_SEMICOLON STREQUAL "")
	    SET(${var} ${_str_list})
	ENDIF(NOT _NOESCAPE_SEMICOLON STREQUAL "")

    ENDMACRO(STRING_SPLIT var delimiter str)

ENDIF(NOT DEFINED _MANAGE_STRING_CMAKE_)

