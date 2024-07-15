cmake_minimum_required(VERSION 3.16)
project(artriculate LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Gui DBus Quick Sql)

qt_policy(SET QTP0001 NEW)
qt_standard_project_setup()

#set(CMAKE_VERBOSE_MAKEFILE true)

qt_add_executable(artriculate
	src/main.cpp src/picturemodel.cpp  src/picturemodel.h
)

target_link_libraries(artriculate PRIVATE
    Qt::Gui
	Qt::DBus
    Qt::Quick
    Qt::Sql
)

find_package(PkgConfig)
pkg_check_modules (SYSTEMD REQUIRED libsystemd)
target_link_libraries(artriculate PRIVATE ${SYSTEMD_LIBRARIES})
add_definitions(-DUSING_SYSTEMD)

#install(TARGETS artriculate
#    RUNTIME DESTINATION "${INSTALL_PATH}"
#    BUNDLE DESTINATION "${INSTALL_PATH}"
#    LIBRARY DESTINATION "${INSTALL_PATH}"
#)

#add_subdirectory(qml)

if(COMPILED_RESOURCES)
  target_compile_definitions(artriculate PUBLIC COMPILED_RESOURCES)
  file(
    GLOB_RECURSE
    artriculate_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    FILES
    "qml/*"
  )
  set(artriculate_QMLISH_FILES ${artriculate_FILES})
  set(artriculate_NON_QMLISH_FILES ${artriculate_FILES})
  list(FILTER artriculate_QMLISH_FILES INCLUDE REGEX ".*\\.(qml|js|mjs)$")
  list(FILTER artriculate_NON_QMLISH_FILES EXCLUDE REGEX ".*\\.(qml|js|mjs)$")
  message(
    DEBUG
    "Compiling QML files: ${artriculate_QMLISH_FILES}"
  )
  message(
    DEBUG
    "Compiling resource files: ${artriculate_NON_QMLISH_FILES}"
  )
  qt_add_qml_module(
    artriculate
    URI Chaos
	#RESOURCE_PREFIX /chaos-reins.com/imports
    QML_FILES
    ${artriculate_QMLISH_FILES}
	RESOURCES
    ${artriculate_NON_QMLISH_FILES}
	#ENABLE_TYPE_COMPILER
  )
else()
  install(
    DIRECTORY qml
  )
endif()
