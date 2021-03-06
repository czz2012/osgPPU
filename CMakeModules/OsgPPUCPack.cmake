# This script sets up packaging targets for each "COMPONENT" as specified in INSTALL commands
#
# for each component a CPackConfig-<component>.cmake is generated in the build tree
# and a target is added to call cpack for it (e.g. package_openscenegaph
# A target for generating a package with everything that gets INSTALLED is generated (package_osgppu-all)
# A target for making all of the abaove packages is generated (package_ALL)
#
# package filenames are created on the form <package>-<platform>-<arch>[-<compiler>]-<build_type>[-static].tar.gz
# ...where compiler optionally set using a cmake gui (OSGPPU_CPACK_COMPILER). This script tries to guess compiler version for msvc generators
# ...build_type matches CMAKE_BUILD_TYPE for all generators but the msvc ones


# resolve architecture. The reason i "change" i686 to i386 is that debian packages
# require i386 so this is for the future
IF("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i686")
    SET(SYSTEM_ARCH "i386")
ELSE("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i686")
    SET(SYSTEM_ARCH ${CMAKE_SYSTEM_PROCESSOR})
ENDIF("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i686")

# set a default system name - use CMake setting (Linux|Windows|...)
SET(SYSTEM_NAME ${CMAKE_SYSTEM_NAME})
#message(STATUS "CMAKE_SYSTEM_NAME ${CMAKE_SYSTEM_NAME}")
#message(STATUS "CMAKE_SYSTEM_PROCESSOR ${CMAKE_SYSTEM_PROCESSOR}")

# for msvc the SYSTEM_NAME is set win32/64 instead of "Windows"
IF(MSVC)
    IF(CMAKE_CL_64)
        SET(SYSTEM_NAME "win64")
    ELSE(CMAKE_CL_64)
        SET(SYSTEM_NAME "win32")
    ENDIF(CMAKE_CL_64)
ENDIF(MSVC)

# Guess the compiler (is this desired for other platforms than windows?)
IF(NOT  OSGPPU_CPACK_COMPILER)
    INCLUDE(OsgDetermineCompiler)
ENDIF(NOT OSGPPU_CPACK_COMPILER)

# expose the compiler setting to the user
SET(OSGPPU_CPACK_COMPILER "${OSG_COMPILER}" CACHE STRING "This ia short string (vc90, vc80sp1, gcc-4.3, ...) describing your compiler. The string is used for creating package filenames")

IF(OSGPPU_CPACK_COMPILER)
  SET(OSGPPU_CPACK_SYSTEM_SPEC_STRING ${SYSTEM_NAME}-${SYSTEM_ARCH}-${OSGPPU_CPACK_COMPILER})
ELSE(OSGPPU_CPACK_COMPILER)
  SET(OSGPPU_CPACK_SYSTEM_SPEC_STRING ${SYSTEM_NAME}-${SYSTEM_ARCH})
ENDIF(OSGPPU_CPACK_COMPILER)


## variables that apply to all packages
SET(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${OSGPPU_VERSION}" CACHE STRING "Package filename used to build the package")


# these goes for all platforms. Setting these stops the CPack.cmake script from generating options about other package compression formats (.z .tz, etc.)
SET(CPACK_GENERATOR "TGZ")
SET(CPACK_SOURCE_GENERATOR "TGZ")


# for ms visual studio we use it's internally defined variable to get the configuration (debug,release, ...) 
IF(MSVC_IDE)
    SET(OSGPPU_CPACK_CONFIGURATION "$(OutDir)")
    SET(PACKAGE_TARGET_PREFIX "Package ")
ELSE(MSVC_IDE)
    # on un*x an empty CMAKE_BUILD_TYPE means release
    IF(CMAKE_BUILD_TYPE)
        SET(OSGPPU_CPACK_CONFIGURATION ${CMAKE_BUILD_TYPE})
    ELSE(CMAKE_BUILD_TYPE)
        SET(OSGPPU_CPACK_CONFIGURATION "Release")
    ENDIF(CMAKE_BUILD_TYPE)
    SET(PACKAGE_TARGET_PREFIX "package_")
ENDIF(MSVC_IDE)


# Get all defined components
# if not defined before, then just build default package
#GET_CMAKE_PROPERTY(CPACK_COMPONENTS_ALL COMPONENTS)
IF(NOT CPACK_COMPONENTS_ALL)
  SET(CPACK_COMPONENTS_ALL libosgPPU)
ENDIF(NOT CPACK_COMPONENTS_ALL)

# Create a target that will be used to generate all packages defined below
#SET(PACKAGE_ALL_TARGETNAME "${PACKAGE_TARGET_PREFIX}ALL")
#ADD_CUSTOM_TARGET(${PACKAGE_ALL_TARGETNAME})

# Macro to generate packages
MACRO(GENERATE_PACKAGING_TARGET package_name)
    SET(CPACK_PACKAGE_NAME ${package_name})

    # the doc packages don't need a system-arch specification
    IF(${package} MATCHES -doc)
        SET(OSGPPU_PACKAGE_FILE_NAME ${package_name}-${OSGPPU_VERSION})
    ELSE(${package} MATCHES -doc)
        SET(OSGPPU_PACKAGE_FILE_NAME "${package_name}-${OSGPPU_VERSION}-${OSGPPU_CPACK_SYSTEM_SPEC_STRING}-${OSGPPU_CPACK_CONFIGURATION}")
        IF(NOT DYNAMIC_OSGPPU)
            SET(OSGPPU_PACKAGE_FILE_NAME "${OSGPPU_PACKAGE_FILE_NAME}-static")
        ENDIF(NOT DYNAMIC_OSGPPU)
    ENDIF(${package} MATCHES -doc)

    # read configuration files
    CONFIGURE_FILE("${osgPPU_SOURCE_DIR}/CMakeModules/OsgPPUCPackConfig.cmake.in" "${osgPPU_BINARY_DIR}/CPackConfig-${package_name}.cmake" IMMEDIATE)

    # setup package name
    SET(PACKAGE_TARGETNAME "${PACKAGE_TARGET_PREFIX}${package_name}")

    # This is naive and will probably need fixing eventually
    IF(MSVC)
        SET(MOVE_COMMAND "move")
    ELSE(MSVC)
        SET(MOVE_COMMAND "mv")
    ENDIF(MSVC)
    
    # Create a target that creates the current package
    # and rename the package to give it proper filename
    ADD_CUSTOM_TARGET(${PACKAGE_TARGETNAME})
    ADD_CUSTOM_COMMAND(TARGET ${PACKAGE_TARGETNAME}
        COMMAND ${CMAKE_CPACK_COMMAND} -C ${OSGPPU_CPACK_CONFIGURATION} --config ${osgPPU_BINARY_DIR}/CPackConfig-${package_name}.cmake
        COMMAND "${MOVE_COMMAND}" "${CPACK_PACKAGE_FILE_NAME}.tar.gz" "${OSGPPU_PACKAGE_FILE_NAME}.tar.gz"
        #COMMAND ${CMAKE_COMMAND} -E echo "renamed ${CPACK_PACKAGE_FILE_NAME}.tar.gz -> ${OSGPPU_PACKAGE_FILE_NAME}.tar.gz"
        COMMENT "Run CPack packaging for ${package_name}..."
    )
    # Add the exact same custom command to the all package generating target. 
    # I can't use add_dependencies to do this because it would allow parallell building of packages so am going brute here
#     ADD_CUSTOM_COMMAND(TARGET ${PACKAGE_ALL_TARGETNAME}
#         COMMAND ${CMAKE_CPACK_COMMAND} -C ${OSGPPU_CPACK_CONFIGURATION} --config ${osgPPU_BINARY_DIR}/CPackConfig-${package_name}.cmake
#         COMMAND "${MOVE_COMMAND}" "${CPACK_PACKAGE_FILE_NAME}.tar.gz" "${OSGPPU_PACKAGE_FILE_NAME}.tar.gz"
#         COMMAND ${CMAKE_COMMAND} -E echo "renamed ${CPACK_PACKAGE_FILE_NAME}.tar.gz -> ${OSGPPU_PACKAGE_FILE_NAME}.tar.gz"
#     )
ENDMACRO(GENERATE_PACKAGING_TARGET)

# Create configs and targets for a package including all components
#SET(OSGPPU_CPACK_COMPONENT ALL)
#GENERATE_PACKAGING_TARGET(osgppu-all)


# -------------------------------------------------
# Create a rule to build group of components
# -------------------------------------------------
MACRO(GENERATE_PACKAGING_GROUP_TARGET group_name)

	# set empty list
	SET(CPACK_INSTALL_CMAKE_PROJECTS "")

	# we have predefined a group (list of components) before this macro
	foreach(component ${PACKAGE_GROUP})
		list(APPEND CPACK_INSTALL_CMAKE_PROJECTS "${PROJECT_BINARY_DIR};${PROJECT_NAME};${component};/")
	endforeach(component)

	# generate package build target for this group
	SET(OSGPPU_CPACK_COMPONENT ${group_name})
	GENERATE_PACKAGING_TARGET(${group_name})
	
ENDMACRO(GENERATE_PACKAGING_GROUP_TARGET)


# Create configs and targets for each component
#FOREACH(package ${CPACK_COMPONENTS_ALL})
#    SET(OSGPPU_CPACK_COMPONENT ${package})
#    GENERATE_PACKAGING_TARGET(${package})
#ENDFOREACH(package ${CPACK_COMPONENTS_ALL})
