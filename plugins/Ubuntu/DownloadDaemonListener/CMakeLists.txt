include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(DOWNLOADDAEMONLISTENER_SOURCES
    plugin.cpp
    DownloadTracker.cpp
    interface/downloadtrackeradaptor.cpp
    )

add_library(DownloadDaemonListener MODULE ${DOWNLOADDAEMONLISTENER_SOURCES})

qt5_use_modules(DownloadDaemonListener Qml Quick DBus Core)
pkg_check_modules(DDLADAPTER REQUIRED udm-common)
add_definitions(${DDLADAPTER_CFLAGS} ${DDLADAPTER_CFLAGS_OTHER})
target_link_libraries(DownloadDaemonListener ${DDLADAPTER_LIBRARIES})
add_unity8_plugin(Ubuntu.DownloadDaemonListener 0.1 Ubuntu/DownloadDaemonListener TARGETS DownloadDaemonListener)
