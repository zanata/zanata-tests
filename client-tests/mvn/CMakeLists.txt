
FOREACH(_proj ${MVN_PROJECTS})
    ADD_PROJECT(${_proj} mvn)
ENDFOREACH()

