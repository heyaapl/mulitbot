#
# This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
#
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

#[=======================================================================[.rst:
FindMySQL
-----------

Find MySQL.

Imported Targets
^^^^^^^^^^^^^^^^

This module defines the following :prop_tgt:`IMPORTED` targets:

``MySQL::MySQL``
  MySQL client library, if found.

Result Variables
^^^^^^^^^^^^^^^^

This module will set the following variables in your project:

``MYSQL_FOUND``
  System has MySQL.
``MYSQL_INCLUDE_DIR``
  MySQL include directory.
``MYSQL_LIBRARY``
  MySQL library.
``MYSQL_EXECUTABLE``
  Path to mysql client binary.

Hints
^^^^^

Set ``MYSQL_ROOT_DIR`` to the root directory of MySQL installation.
#]=======================================================================]

set(MYSQL_FOUND 0)

set(_MYSQL_ROOT_HINTS
  ${MYSQL_ROOT_DIR}
  ENV MYSQL_ROOT_DIR
)

set(MYSQL_MINIMUM_VERSION "8.0")

function(check_mysql_version)
  if(MYSQL_CONFIG)
    execute_process(
      COMMAND "${MYSQL_CONFIG}" --version
      OUTPUT_VARIABLE MYSQL_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(MYSQL_VERSION VERSION_LESS MYSQL_MINIMUM_VERSION)
      message(FATAL_ERROR "MySQL version found (${MYSQL_VERSION}) is less than the required version (${MYSQL_MINIMUM_VERSION})")
    else()
      message(STATUS "Found MySQL version: ${MYSQL_VERSION}")
    endif()
  endif()
endfunction()

if(UNIX)
  set(MYSQL_CONFIG_PREFER_PATH "$ENV{MYSQL_HOME}/bin" CACHE FILEPATH
    "preferred path to MySQL (mysql_config)"
  )

  find_program(MYSQL_CONFIG mysql_config
    ${MYSQL_CONFIG_PREFER_PATH}
    /usr/local/mysql/bin/
    /usr/local/bin/
    /usr/bin/
  )

  if(MYSQL_CONFIG)
    message(STATUS "Using mysql-config: ${MYSQL_CONFIG}")
    # set INCLUDE_DIR
    execute_process(
      COMMAND "${MYSQL_CONFIG}" --include
      OUTPUT_VARIABLE MY_TMP
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(REGEX REPLACE "-I([^ ]*)( .*)?" "\\1" MY_TMP "${MY_TMP}")
    set(MYSQL_ADD_INCLUDE_PATH ${MY_TMP} CACHE FILEPATH INTERNAL)
    #message("[DEBUG] MYSQL ADD_INCLUDE_PATH : ${MYSQL_ADD_INCLUDE_PATH}")
    # set LIBRARY_DIR
    execute_process(
      COMMAND "${MYSQL_CONFIG}" --libs_r
      OUTPUT_VARIABLE MY_TMP
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(MYSQL_ADD_LIBRARIES "")
    string(REGEX MATCHALL "-l[^ ]*" MYSQL_LIB_LIST "${MY_TMP}")
    foreach(LIB ${MYSQL_LIB_LIST})
      string(REGEX REPLACE "[ ]*-l([^ ]*)" "\\1" LIB "${LIB}")
      list(APPEND MYSQL_ADD_LIBRARIES "${LIB}")
      #message("[DEBUG] MYSQL ADD_LIBRARIES : ${MYSQL_ADD_LIBRARIES}")
    endforeach(LIB ${MYSQL_LIB_LIST})

    set(MYSQL_ADD_LIBRARIES_PATH "")
    string(REGEX MATCHALL "-L[^ ]*" MYSQL_LIBDIR_LIST "${MY_TMP}")
    foreach(LIB ${MYSQL_LIBDIR_LIST})
      string(REGEX REPLACE "[ ]*-L([^ ]*)" "\\1" LIB "${LIB}")
      list(APPEND MYSQL_ADD_LIBRARIES_PATH "${LIB}")
      #message("[DEBUG] MYSQL ADD_LIBRARIES_PATH : ${MYSQL_ADD_LIBRARIES_PATH}")
    endforeach(LIB ${MYSQL_LIBS})

  else(MYSQL_CONFIG)
    set(MYSQL_ADD_LIBRARIES "")
    list(APPEND MYSQL_ADD_LIBRARIES "mysqlclient_r")
  endif(MYSQL_CONFIG)
endif(UNIX)

set(_MYSQL_ROOT_PATHS)

if(WIN32)
  # read environment variables and change \ to /
  file(TO_CMAKE_PATH "$ENV{PROGRAMFILES}" PROGRAM_FILES_32)
  file(TO_CMAKE_PATH "$ENV{ProgramW6432}" PROGRAM_FILES_64)

  cmake_host_system_information(
    RESULT
      _MYSQL_ROOT_HINTS_SUBKEYS
    QUERY
      WINDOWS_REGISTRY
      "HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB" SUBKEYS
    VIEW BOTH
  )
  list(SORT _MYSQL_ROOT_HINTS_SUBKEYS COMPARE NATURAL ORDER DESCENDING)

  set(_MYSQL_ROOT_HINTS_REGISTRY_LOCATIONS)
  foreach(subkey IN LISTS _MYSQL_ROOT_HINTS_SUBKEYS)
    cmake_host_system_information(
      RESULT
        _MYSQL_ROOT_HINTS_REGISTRY_LOCATION
      QUERY
        WINDOWS_REGISTRY
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB\\${subkey}" VALUE "Location"
      VIEW BOTH
    )
    list(APPEND _MYSQL_ROOT_HINTS_REGISTRY_LOCATIONS ${_MYSQL_ROOT_HINTS_REGISTRY_LOCATION})
  endforeach()

  file(GLOB _MYSQL_ROOT_PATHS_VERSION_SUBDIRECTORIES
    LIST_DIRECTORIES TRUE
    "${PROGRAM_FILES_64}/MySQL/MySQL Server *"
    "${PROGRAM_FILES_32}/MySQL/MySQL Server *"
    "$ENV{SystemDrive}/MySQL/MySQL Server *"
  )

  list(SORT _MYSQL_ROOT_PATHS_VERSION_SUBDIRECTORIES COMPARE NATURAL ORDER DESCENDING)

  set(_MYSQL_ROOT_PATHS
    ${_MYSQL_ROOT_PATHS}
	${_MYSQL_ROOT_PATHS_VERSION_SUBDIRECTORIES}
    "${PROGRAM_FILES_64}/MySQL"
    "${PROGRAM_FILES_32}/MySQL"
    "$ENV{SystemDrive}/MySQL"
  )
endif(WIN32)

find_path(MYSQL_INCLUDE_DIR
  NAMES
    mysql.h
  HINTS
    ${_MYSQL_ROOT_HINTS}
  PATHS
    ${MYSQL_ADD_INCLUDE_PATH}
    /usr/include
    /usr/include/mysql
    /usr/local/include
    /usr/local/include/mysql
    /usr/local/mysql/include
	${_MYSQL_ROOT_PATHS}
  PATH_SUFFIXES
    include
    include/mysql
  DOC
    "Specify the directory containing mysql.h."
)

if(UNIX)
  foreach(LIB ${MYSQL_ADD_LIBRARIES})
    find_library(MYSQL_LIBRARY
      NAMES
        mysql libmysql ${LIB}
      PATHS
        ${MYSQL_ADD_LIBRARIES_PATH}
        /usr/lib
        /usr/lib/mysql
        /usr/local/lib
        /usr/local/lib/mysql
        /usr/local/mysql/lib
      DOC "Specify the location of the mysql library here."
    )
  endforeach(LIB ${MYSQL_ADD_LIBRARY})
endif(UNIX)

if(WIN32)
  find_library(MYSQL_LIBRARY
    NAMES
      libmysql
    HINTS
      ${_MYSQL_ROOT_HINTS}
    PATHS
      ${MYSQL_ADD_LIBRARIES_PATH}
      ${_MYSQL_ROOT_PATHS}
    PATH_SUFFIXES
      lib
      lib/opt
    DOC "Specify the location of the mysql library here."
  )
endif(WIN32)

# On Windows you typically don't need to include any extra libraries
# to build MYSQL stuff.

if(NOT WIN32)
  find_library(MYSQL_EXTRA_LIBRARIES
    NAMES
      z zlib
    PATHS
      /usr/lib
      /usr/local/lib
    DOC
      "if more libraries are necessary to link in a MySQL client (typically zlib), specify them here."
  )
else(NOT WIN32)
  set(MYSQL_EXTRA_LIBRARIES "")
endif(NOT WIN32)

if(UNIX)
    find_program(MYSQL_EXECUTABLE mysql
    PATHS
        ${MYSQL_CONFIG_PREFER_PATH}
        /usr/local/mysql/bin/
        /usr/local/bin/
        /usr/bin/
    DOC
        "path to your mysql binary."
    )
endif(UNIX)

if(WIN32)
  find_program(MYSQL_EXECUTABLE mysql
    HINTS
      ${_MYSQL_ROOT_HINTS}
    PATHS
      ${_MYSQL_ROOT_PATHS}
    PATH_SUFFIXES
      bin
      bin/opt
    DOC
      "path to your mysql binary."
  )
endif(WIN32)

unset(MySQL_lib_WANTED)
unset(MySQL_binary_WANTED)
set(MYSQL_REQUIRED_VARS "")
foreach(_comp IN LISTS MySQL_FIND_COMPONENTS)
  if(_comp STREQUAL "lib")
    set(MySQL_${_comp}_WANTED TRUE)
	if(MySQL_FIND_REQUIRED_${_comp})
	  list(APPEND MYSQL_REQUIRED_VARS "MYSQL_LIBRARY")
	  list(APPEND MYSQL_REQUIRED_VARS "MYSQL_INCLUDE_DIR")
	endif()
    if(EXISTS "${MYSQL_LIBRARY}" AND EXISTS "${MYSQL_INCLUDE_DIR}")
      set(MySQL_${_comp}_FOUND TRUE)
    else()
      set(MySQL_${_comp}_FOUND FALSE)
    endif()
  elseif(_comp STREQUAL "binary")
    set(MySQL_${_comp}_WANTED TRUE)
	if(MySQL_FIND_REQUIRED_${_comp})
	  list(APPEND MYSQL_REQUIRED_VARS "MYSQL_EXECUTABLE")
	endif()
    if(EXISTS "${MYSQL_EXECUTABLE}" )
      set(MySQL_${_comp}_FOUND TRUE)
    else()
      set(MySQL_${_comp}_FOUND FALSE)
    endif()
  else()
    message(WARNING "${_comp} is not a valid MySQL component")
    set(MySQL_${_comp}_FOUND FALSE)
  endif()
endforeach()
unset(_comp)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MySQL
  REQUIRED_VARS
    ${MYSQL_REQUIRED_VARS}
  HANDLE_COMPONENTS
  FAIL_MESSAGE
    "Could not find the MySQL libraries! Please install the development libraries and headers"
)
unset(MYSQL_REQUIRED_VARS)

if(MYSQL_FOUND)
  if(MySQL_lib_WANTED AND MySQL_lib_FOUND)
    message(STATUS "Found MySQL library: ${MYSQL_LIBRARY}")
    message(STATUS "Found MySQL headers: ${MYSQL_INCLUDE_DIR}")
  endif()
  if(MySQL_binary_WANTED AND MySQL_binary_FOUND)
    message(STATUS "Found MySQL executable: ${MYSQL_EXECUTABLE}")
  endif()
  mark_as_advanced(MYSQL_FOUND MYSQL_LIBRARY MYSQL_EXTRA_LIBRARIES MYSQL_INCLUDE_DIR MYSQL_EXECUTABLE)

  check_mysql_version()

  if(NOT TARGET MySQL::MySQL AND MySQL_lib_WANTED AND MySQL_lib_FOUND)
    add_library(MySQL::MySQL UNKNOWN IMPORTED)
    set_target_properties(MySQL::MySQL
      PROPERTIES
        IMPORTED_LOCATION
          "${MYSQL_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES
          "${MYSQL_INCLUDE_DIR}")
  endif()
else()
  message(FATAL_ERROR "Could not find the MySQL libraries! Please install the development libraries and headers")
endif()