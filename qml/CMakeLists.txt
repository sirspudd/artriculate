if(COMPILED_RESOURCES)
  target_compile_definitions(artriculate PUBLIC COMPILED_RESOURCES)
  file(
    GLOB_RECURSE
    artriculate_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    FILES
    "*"
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
  qt_add_resources(
    artriculate
    FILES
    ${artriculate_NON_QMLISH_FILES}
  )
  qt_add_qml_module(
    artriculate
    URI Chaos
    QML_FILES
    ${artriculate_QMLISH_FILES}
  )
else()
  install(
    DIRECTORY qml
  )
endif()
