####################################################################
# REST tests
####################################################################

#===================================================================
# Target name convention
# ${TARGET_TYPE}_${client}_${proj}_${ver}_${target}
#

#===================================================================
# Base requirement
#

MACRO(REQUIRE_CMD var cmd)
    FIND_PROGRAM(${var} "${cmd}" ${ARGN})
    IF("${${var}}" MATCHES "NOTFOUND$")
	MESSAGE(FATAL "${cmd} is not installed")
    ENDIF("${${var}}" MATCHES "NOTFOUND$")
ENDMACRO(REQUIRE_CMD var cmd)

REQUIRE_CMD(PUBLICAN_CMD publican)
REQUIRE_CMD(ZANATA_ZANATA_XML_MAKE_CMD zanata_zanata_xml_make)
REQUIRE_CMD(ZANATA_POM_XML_MAKE_CMD zanata_pom_xml_make)

SET(ZANATAC_CMD "${SCRIPT_DIR}/zanatac" "--yes" "--show")
SET(ZANATA_MVN_CMD ${ZANATAC_CMD})
SET(ZANATA_PY_CMD  ${ZANATAC_CMD} --client py)

ADD_CUSTOM_COMMAND(OUTPUT ${SAMPLE_PROJ_DIR_ABSOLUTE}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${SAMPLE_PROJ_DIR_ABSOLUTE}
    )

# Targets performed by clients
SET(CLIENT_TARGET "rest")
SET(CLIENT_TARGET_SUBTARGETS "verify" "pull" "push" "version-put" "project-put")

SET(PREPARE_TARGET "prepare")
SET(PREPARE_TARGET_SUBTARGETS zanata_xml pom_xml)
# Targets that are not performed by clients
SET(PROJECT_TARGETS prepare ${PREPARE_TARGET_SUBTARGETS})

SET(TARGET_TYPES CLIENT_TARGET PREPARE_TARGET)

# Build top targets
ADD_CUSTOM_TARGET(${PREPARE_TARGET}
    COMMENT "${PREPARE_TARGET} all projects"
    )

FOREACH(_client "mvn" "py")
    ADD_CUSTOM_TARGET(${CLIENT_TARGET}_${_client}
	COMMENT "REST tests on ${_client} client for all projects"
	)
ENDFOREACH()


#===================================================================
# Macros
#

##SET_ABSOLUTE_PATHS proj [ver [client]])
MACRO(SET_ABSOLUTE_PATHS proj)
    SET(ver "")
    SET(_client "")

    FOREACH(_arg ${ARGN})
	IF ("${ver}" STREQUAL "")
	    SET(ver "${_arg}")
	ELSEIF ("${_client}" STREQUAL "")
	    SET(_client "${_arg}")
	ENDIF()
    ENDFOREACH()

    SET(_proj_dir "${SAMPLE_PROJ_DIR_ABSOLUTE}/${proj}")
    SET(_proj_dir_stamp ${_proj_dir}/.stamp)
    SET(_proj_ver_dir "${_proj_dir}/${ver}")
    SET(_proj_ver_scm_dir "${_proj_ver_dir}/.${${proj}_REPO_TYPE}")
    SET(_proj_ver_base_dir "${_proj_ver_dir}/${${proj}_BASE_DIR}")

    ## publican.cfg
    SET(_proj_ver_publican_cfg
	"${_proj_ver_base_dir}/publican.cfg")
    SET(_proj_ver_publican_cfg_striped
	"${_proj_ver_publican_cfg}.striped")

    ## pom.xml
    SET(_proj_ver_pom_xml "${_proj_ver_base_dir}/pom.xml")
    SET(_proj_ver_pom_xml_stamp "${_proj_ver_pom_xml}.stamp")

    ## zanata.xml
    IF("${${proj}_ZANATA_XML}" STREQUAL "")
	SET(_proj_ver_zanata_xml ${_proj_ver_base_dir}/zanata.xml)
    ELSE("${${proj}_ZANATA_XML}" STREQUAL "")
	SET(_proj_ver_zanata_xml ${_proj_ver_base_dir}/${${proj}_ZANATA_XML})
	LIST(APPEND _zanata_xml_make_opts "--zanataXml" "${${proj}_ZANATA_XML}")
    ENDIF("${${proj}_ZANATA_XML}" STREQUAL "")

    ## _pull_dest_dir
    IF(NOT "${_client}" STREQUAL "")
	SET(_proj_ver_pull_dest_dir ${PULL_DEST_DIR_ABSOLUTE}/${_client}/${proj}/${ver})
    ENDIF(NOT "${_client}" STREQUAL "")

    ## src_dir and trans_dir
    GET_ACTUAL_SRC_DIR( _src_dir ${proj})
    SET(_proj_ver_src_dir ${_proj_ver_base_dir}/${_src_dir})
    SET(_proj_ver_trans_dir ${_proj_ver_base_dir}/${${proj}_TRANS_DIR})
ENDMACRO(SET_ABSOLUTE_PATHS proj)


#===================================================================
# Document project targets
#

SET(PROJECT_PROPERTIES REPO_TYPE PROJECT_TYPE)
SET(REPO_TYPE_DEFAULT "git")
SET(PROJECT_TYPE_DEFAULT "podir")

MACRO(PROJECT_COMMON_SETUP proj)
    FOREACH(_prop ${PROJECT_PROPERTIES})
	IF(NOT DEFINED ${proj}_${_prop})
	    SET(${proj}_${_prop} ${${_prop}_DEFAULT})
	ENDIF(NOT DEFINED ${proj}_${_prop})
	# MESSAGE("${proj}_${_prop}=${${proj}_${_prop}}")
    ENDFOREACH(_prop ${PROJECT_PROPERTIES})
    # Project wide zanata.xml (means: no ver info yet)
    SET_ABSOLUTE_PATHS(${proj})

    ## Create project targets
    ADD_CUSTOM_TARGET(${PREPARE_TARGET}_${proj})
    ADD_DEPENDENCIES(${PREPARE_TARGET} ${PREPARE_TARGET}_${proj})

    ## Build necessary directory and files for push
    ADD_CUSTOM_COMMAND(OUTPUT ${_proj_dir_stamp}
	COMMAND ${CMAKE_COMMAND} -E make_directory ${_proj_dir}
	COMMAND ${CMAKE_COMMAND} -E touch ${_proj_dir_stamp}
	DEPENDS ${SAMPLE_PROJ_DIR_ABSOLUTE}
	)
ENDMACRO(PROJECT_COMMON_SETUP proj)

MACRO(GET_ACTUAL_SRC_DIR var proj)
    SET(${var} "")
    IF("${${proj}_SRC_DIR}" STREQUAL "")
	IF("${${proj}_PROJECT_TYPE}" STREQUAL "podir")
	    SET(${var} "pot")
	ENDIF("${${proj}_PROJECT_TYPE}" STREQUAL "podir")
    ELSE()
	SET(${var} "${${proj}_SRC_DIR}")
    ENDIF()
ENDMACRO()

MACRO(MAKE_OPTS var proj ver)
    GET_ACTUAL_SRC_DIR(_src_dir ${proj})
    IF(NOT "${_src_dir}" STREQUAL "")
	LIST(APPEND ${var} "--srcDir" "${_src_dir}")
    ENDIF()

    IF(NOT "${${proj}_TRANS_DIR}" STREQUAL "")
	LIST(APPEND ${var} "--transDir" "${${proj}_TRANS_DIR}")
    ENDIF()
ENDMACRO(MAKE_OPTS var proj ver)

MACRO(MAKE_ZANATA_XML proj ver proj_ver_dir)
    SET_ABSOLUTE_PATHS(${proj} ${ver})
    SET(_zanata_xml_make_opts "--projectType" "${${proj}_PROJECT_TYPE}")
    LIST(APPEND _zanata_xml_make_opts "--backupSuffix" ".stamp")
    MAKE_OPTS(_zanata_xml_make_opts ${proj} ${ver})

    ADD_CUSTOM_TARGET(${PREPARE_TARGET}_${proj}_${ver}_zanata_xml
	COMMAND ${ZANATA_ZANATA_XML_MAKE_CMD} ${_zanata_xml_make_opts} ${ZANATA_URL} ${proj} ${ver}
	DEPENDS "${_proj_ver_publican_cfg_striped}"
	COMMENT "[${proj}-${ver}] make ${_proj_ver_zanata_xml}"
	WORKING_DIRECTORY ${_proj_ver_base_dir}
	VERBATIM
	)

    ADD_CUSTOM_COMMAND(OUTPUT ${_proj_ver_zanata_xml}
	COMMAND ${ZANATA_ZANATA_XML_MAKE_CMD} ${_zanata_xml_make_opts} ${ZANATA_URL} ${proj} ${ver}
	DEPENDS "${_proj_ver_publican_cfg_striped}"
	COMMENT "[${proj}-${ver}] make ${_proj_ver_zanata_xml}"
	WORKING_DIRECTORY ${_proj_ver_base_dir}
	VERBATIM
	)

ENDMACRO(MAKE_ZANATA_XML proj ver proj_ver_dir)


MACRO(MAKE_POM_XML_OPTS var proj prefix)
    SET(${var} "")
    MAKE_OPTS(${var} ${prefix} ${ver})

    LIST(APPEND ${var} "--backupSuffix" ".stamp")

    IF(NOT "${proj}" STREQUAL "${prefix}")
	LIST(APPEND ${var} "--noPluginRepostories")
    ENDIF()

    IF(${prefix}_ENABLE_MODULE)
	LIST(APPEND ${var} "--enableModules")
    ENDIF()

    IF(${prefix}_SKIP)
	LIST(APPEND ${var} "--skip")
    ENDIF()

    IF(NOT "${${prefix}_INCLUDES}" STREQUAL "")
	LIST(APPEND ${var} "--includes" "${${prefix}_INCLUDES}")
    ENDIF()

    IF(NOT "${${prefix}_EXCLUDES}" STREQUAL "")
	LIST(APPEND ${var} "--excludes" "${${prefix}_EXCLUDES}")
    ENDIF()

ENDMACRO(MAKE_POM_XML_OPTS var proj ver proj_ver_dir)

MACRO(MAKE_POM_XML proj ver proj_ver_dir)
    SET_ABSOLUTE_PATHS(${proj} ${ver})

    SET(_stamp_list "")
    SET(_target_list "")
    SET(_targetNamePrefix "${PREPARE_TARGET}_${proj}_${ver}")
    # Generate "sub" pom.xml
    FOREACH(_pomXmlProf ${${proj}_POM_XML_LIST})
	SET(_pom_xml "${proj_base_ver_dir}/${${_pomXmlProf}}")
	SET(_pom_xml_stamp "${_pom_xml}.stamp")
	#    MESSAGE("_pomXml=${_pomXml}")

	MAKE_POM_XML_OPTS(_pom_xml_make_opts ${proj} ${_pomXmlProf})

	ADD_CUSTOM_COMMAND(OUTPUT "${_pom_xml_stamp}"
	    COMMAND ${ZANATA_POM_XML_MAKE_CMD} ${_pom_xml_make_opts} "${${_pomXmlProf}}"
	    COMMAND ${CMAKE_COMMAND} -E touch "${${_pomXmlProf}}.stamp"
	    WORKING_DIRECTORY ${_proj_ver_base_dir}
	    DEPENDS "${_proj_ver_scm_dir}"
	    COMMENT "[${proj}-${ver}] Updating ${_pom_xml}"
	    )

	ADD_CUSTOM_TARGET(${_targetNamePrefix}_${_pomXmlProf}
	    COMMAND ${ZANATA_POM_XML_MAKE_CMD} ${_pom_xml_make_opts} "${${_pomXmlProf}}"
	    COMMAND ${CMAKE_COMMAND} -E touch "${${_pomXmlProf}}.stamp"
	    WORKING_DIRECTORY ${_proj_ver_base_dir}
	    DEPENDS "${_proj_ver_scm_dir}"
	    COMMENT "[${proj}-${ver}] Updating ${_pom_xml}"
	    )

	LIST(APPEND _stamp_list "${_pom_xml_stamp}")
	LIST(APPEND _target_list "${_targetNamePrefix}_${_pomXmlProf}")
    ENDFOREACH(_pomXmlProf ${${proj}_POM_XML_LIST})

    SET(_pom_xml "${_proj_ver_base_dir}/pom.xml")
    SET(_pom_xml_stamp "${_pom_xml}.stamp")

    MAKE_POM_XML_OPTS(_pom_xml_make_opts ${proj} ${proj})

    ADD_CUSTOM_COMMAND(OUTPUT "${_pom_xml_stamp}"
	COMMAND ${ZANATA_POM_XML_MAKE_CMD} ${_pom_xml_make_opts} pom.xml
	COMMAND ${CMAKE_COMMAND} -E touch pom.xml.stamp
	WORKING_DIRECTORY ${_proj_ver_base_dir}
	DEPENDS "${_proj_ver_scm_dir}" ${_stamp_list}
	COMMENT "[${proj}-${ver}] Updating ${_pom_xml}"
	)


    ADD_CUSTOM_TARGET(${_targetNamePrefix}_pom_xml
	COMMAND ${ZANATA_POM_XML_MAKE_CMD} ${_pom_xml_make_opts} pom.xml
	COMMAND ${CMAKE_COMMAND} -E touch pom.xml.stamp
	WORKING_DIRECTORY ${_proj_ver_base_dir}
	DEPENDS "${_proj_ver_scm_dir}"
	COMMENT "[${proj}-${ver}] Making ${_pom_xml}"
	)

    IF(_target_list)
	ADD_DEPENDENCIES(${_targetNamePrefix}_pom_xml ${_target_list})
    ENDIF()
ENDMACRO(MAKE_POM_XML proj ver base_dir)

MACRO(PREPARE_PROJECT proj ver)
    SET_ABSOLUTE_PATHS(${proj} ${ver})

    # MESSAGE("proj=${proj} ver=${ver} _proj_ver_pom_xml_stamp=${_proj_ver_pom_xml_stamp} _proj_ver_zanata_xml=${_proj_ver_zanata_xml}")
    SET(_projTargetName ${PREPARE_TARGET}_${proj})
    ADD_CUSTOM_TARGET(${_projTargetName}_${ver}
	DEPENDS ${_proj_ver_pom_xml_stamp} ${_proj_ver_zanata_xml}
	COMMENT "[${proj}-${ver}] preparing"
	)

    ## Download
    ADD_CUSTOM_COMMAND(OUTPUT ${_proj_ver_scm_dir}
	COMMAND perl ${SCRIPT_DIR}/get_project.pl  ${proj} ${ver}
	${${proj}_REPO_TYPE} ${${proj}_URL_${ver}}
	DEPENDS ${_proj_dir_stamp}
	COMMENT "[${proj}-${ver}] Download source from ${${proj}_URL_${ver}}"
	WORKING_DIRECTORY ${SAMPLE_PROJ_DIR_ABSOLUTE}
	VERBATIM
	)

    SET(_post_download_cmd "")
    IF(NOT "${${proj}_POST_DOWNLOAD_CMD}" STREQUAL "")
	SET(_post_download_cmd "COMMAND" "eval" "${${proj}_POST_DOWNLOAD_CMD}")
    ENDIF(NOT "${${proj}_POST_DOWNLOAD_CMD}" STREQUAL "")

    ADD_CUSTOM_COMMAND(OUTPUT "${_proj_ver_publican_cfg_striped}" "${_proj_ver_src_dir}" "${_proj_ver_trans_dir}"
	${_post_download_cmd}
	COMMAND ${SCRIPT_DIR}/generate_trans_template.sh "${LANGS}"
	WORKING_DIRECTORY ${_proj_ver_base_dir}
	DEPENDS "${_proj_ver_scm_dir}"
	COMMENT "[${proj}-${ver}] Generating translation files (.pot and .po)"
	VERBATIM
	)

    ## Make zanata.xml
    MAKE_ZANATA_XML(${proj} ${ver} ${_proj_ver_dir})

    ## Make pom.xml
    MAKE_POM_XML(${proj} ${ver} ${_proj_ver_dir})

    ## Project targets depends on their versions
    ADD_DEPENDENCIES(${_projTargetName} ${_projTargetName}_${ver})

    ## Prepare project version by doing all the dependencies
    FOREACH(_target ${PREPARE_TARGET_SUBTARGETS})
	ADD_DEPENDENCIES(${_projTargetName}_${ver} ${_target}_${proj}_${ver})
    ENDFOREACH(_target ${PREPARE_TARGET_SUBTARGETS})

    ## Build necessary directory and files for pull
    #    FOREACH(_client "mvn" "py")
    #	SET(_proj_ver_pull_dest_dir ${PULL_DEST_DIR_ABSOLUTE}/${_client}/${proj}/${ver})
    #	ADD_CUSTOM_COMMAND(OUTPUT ${_proj_ver_pull_dest_dir}
    #	    COMMAND ${CMAKE_COMMAND} -E make_directory ${_proj_ver_pull_dest_dir}
    #	    COMMENT "[${proj}] make pull directory ${_proj_ver_pull_dest_dir}"
    #	    VERBATIM
    #	    )
    #
    #ENDFOREACH(_client "mvn" "py")
ENDMACRO(PREPARE_PROJECT proj ver)

MACRO(REST_VERIFY proj ver client)
    SET_ABSOLUTE_PATHS(${proj} ${ver} ${client})
    # Note that verifying properties projects is not implemented yet

    # MESSAGE("proj=${proj} ver=${ver} ${proj}_PROJECT_TYPE=|${${proj}_PROJECT_TYPE}| client=${client}")
    STRING_JOIN(_targetName "_" ${CLIENT_TARGET} ${client} ${proj} ${ver} verify)
    IF("${${proj}_PROJECT_TYPE}" STREQUAL "podir")
	ADD_CUSTOM_TARGET(${_targetName}
	    COMMAND ${SCRIPT_DIR}/compare_translation_dir.sh
	    "${_proj_ver_src_dir}"
	    "${_proj_ver_trans_dir}"
	    "${_proj_ver_pull_dest_dir}"
	    "${LANGS}"
	    COMMENT "[${client}][${proj}-${ver}] Verifying the pulled contents with original translation"
	    VERBATIM
	    )
    ELSEIF("${${proj}_PROJECT_TYPE}" STREQUAL "gettext")
	ADD_CUSTOM_TARGET(${_targetName}
	    COMMAND ${SCRIPT_DIR}/compare_translation_dir.sh -g
	    "${_proj_ver_base_dir}/${${proj}_POT}"
	    "${_proj_ver_trans_dir}"
	    "${_proj_ver_pull_dest_dir}"
	    "${LANGS}"
	    COMMENT "[${client}][${proj}-${ver}] Verifying the pulled contents with original translation"
	    VERBATIM
	    )
    ELSE("${${proj}_PROJECT_TYPE}" STREQUAL "podir")
	# Verification on other project types are not supported yet
	ADD_CUSTOM_TARGET(${_targetName}
	    COMMENT "[${client}][${proj}-${ver}] Verifying the pulled contents with ${${proj}_PROJECT_TYPE} is not supported"
	    VERBATIM
	    )

    ENDIF("${${proj}_PROJECT_TYPE}" STREQUAL "podir")

ENDMACRO(REST_VERIFY proj ver client)

MACRO(ADD_PROJECT proj client)
    ## Project "common" setup
    ## 1. Create project common targets
    ## 2. Create a project directory
    ## 3. A zanata.xml for dependency to hook on
    IF(NOT TARGET prepare_${proj})
	PROJECT_COMMON_SETUP(${proj})
    ENDIF()

    STRING_JOIN(_clientTargetName "_" ${CLIENT_TARGET} ${client})
    STRING_JOIN(_projTargetName "_" ${CLIENT_TARGET} ${client} ${proj})
    ADD_CUSTOM_TARGET(${_projTargetName}
	COMMENT "[${proj}] REST ${client} client test"
	)
    ADD_DEPENDENCIES(${_clientTargetName} ${_projTargetName})

    ## For each version
    FOREACH(ver ${${proj}_VERS})
	## Prepare project: To make project workable with zanata,
	## such as generate zanata.xml, pot, pom.xml and publican
	IF(NOT TARGET prepare_${proj}_${ver})
	    PREPARE_PROJECT(${proj} ${ver})
	ENDIF()

	STRING_JOIN(_projTargetName "_" ${CLIENT_TARGET} ${client} ${proj})
	SET(_projVerTargetName "${_projTargetName}_${ver}")
	#MESSAGE("_projTargetName=${_projTargetName} _projVerTargetName=${_projVerTargetName}")
	ADD_CUSTOM_TARGET(${_projVerTargetName}
	    COMMENT "[${proj}-${ver}] REST ${client} client test"
	    )
	ADD_DEPENDENCIES(${_projTargetName} ${_projVerTargetName})

	SET_ABSOLUTE_PATHS(${proj} ${ver} ${client})
	##
	SET(_prev_subtarget "")

	## Foreach client target
	FOREACH(_subtarget ${CLIENT_TARGET_SUBTARGETS})
	    ## Add subtarget
	    SET(_projVerSubTargetName "${_projVerTargetName}_${_subtarget}")
	    IF("${_subtarget}" STREQUAL "verify")
		REST_VERIFY(${proj} ${ver} ${client})
		ADD_DEPENDENCIES(${_projVerTargetName} ${_projVerSubTargetName})
	    ELSE()
		SET(ZANATAC_CMD_OPTS "--client" "${client}")
		SET(_add_custom_target_opts "")
		SET(_pre_cmds "")

		SET(_zanatac_arg_opts
		    "--user-config"		"${CMAKE_SOURCE_DIR}/zanata.ini"
		    "--url"			"${ZANATA_URL}"
		    )
		MAKE_OPTS(_zanatac_arg_opts ${proj} ${ver})

		IF(NOT "${${proj}_ZANATA_XML}" STREQUAL "")
		    LIST(APPEND _zanatac_arg_opts "--project-config"
			"${_proj_ver_base_dir}/${${proj}_ZANATA_XML}")
		ENDIF(NOT "${${proj}_ZANATA_XML}" STREQUAL "")

		## Target specific options
		IF("${_subtarget}" STREQUAL "push")
		    LIST(APPEND _zanatac_arg_opts "--push-trans"
			"--no-copytrans")
		ELSEIF("${_subtarget}" STREQUAL "pull")
		    LIST(APPEND _pre_cmds COMMAND rm "-fr" "${_proj_ver_pull_dest_dir}")
		    LIST(APPEND _pre_cmds COMMAND mkdir "-p" "${_proj_ver_pull_dest_dir}")
		    LIST(APPEND _zanatac_arg_opts "--transdir" "${_proj_ver_pull_dest_dir}")
		    LIST(APPEND _zanatac_arg_opts "--createskeletons")
		ELSEIF("${_subtarget}" STREQUAL "project-put")
		    LIST(INSERT _zanatac_arg_opts 0 "${proj}")
		    LIST(APPEND _zanatac_arg_opts
			"--project-name" "${${proj}_NAME}"
			"--project-desc" "${${proj}_DESC}"
			)
		ELSEIF("${_subtarget}" STREQUAL "version-put")
		    LIST(INSERT _zanatac_arg_opts 0 "${ver}")
		    LIST(APPEND _zanatac_arg_opts
			"--project-id" "${proj}"
			)
		ENDIF("${_subtarget}" STREQUAL "push")

		ADD_CUSTOM_TARGET(${_projVerSubTargetName}
		    ${_pre_cmds}
		    COMMAND ${ZANATAC_CMD} ${ZANATAC_CMD_OPTS} ${_subtarget} ${_zanatac_arg_opts}
		    WORKING_DIRECTORY ${_proj_ver_base_dir}
		    COMMENT "[${client}:${proj}_${ver}] Doing ${_subtarget}"
		    ${_add_custom_target_opts}
		    VERBATIM
		    )
	    ENDIF()

	    ## Add this target as dependency of prev target
	    IF(NOT "${_prev_subtarget}" STREQUAL "")
		ADD_DEPENDENCIES(${_projVerTargetName}_${_prev_subtarget} ${_projVerSubTargetName})
	    ENDIF()

	    ## prev target <- this target
	    SET(_prev_subtarget ${_subtarget})
	ENDFOREACH()

	IF(NOT "${_prev_subtarget}" STREQUAL "")
	    ## tail target should use prepare_proj_ver as dependency
	    ADD_DEPENDENCIES(${_projVerTargetName}_${_prev_subtarget} prepare_${proj}_${ver})
	ENDIF()
    ENDFOREACH(ver ${${proj}_VERS})
ENDMACRO(ADD_PROJECT proj client)

#===================================================================
# Start adding projects
#
FOREACH(_client mvn py)
    FOREACH(_proj ${${_client}_PROJECTS})
	ADD_PROJECT(${_proj} ${_client})
    ENDFOREACH()
ENDFOREACH(_client mvn py)

#===================================================================
# Targets to process only projects that have selenium tests associated.
#
ADD_CUSTOM_TARGET(selenium_projects
    COMMENT "   Preparing projects for selenium tests"
    )

ADD_CUSTOM_TARGET(prepare_selenium_projects
    COMMENT "   Generate zanata.xml for selenium testing projects"
    )

ADD_DEPENDENCIES(prepare_selenium_projects
    prepare_ReleaseNotes_f13 prepare_SecurityGuide_f13)

ADD_DEPENDENCIES(selenium_projects zanata_push_mvn_ReleaseNotes_f13
    zanata_push_mvn_SecurityGuide_f13)

