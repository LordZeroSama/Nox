cmake_minimum_required(VERSION 3.21)
project(nox-home VERSION 0.3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Gui Qml Quick Network)

add_executable(nox-home main.cpp launcher.cpp launcher.h resources.qrc)
target_link_libraries(nox-home PRIVATE Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Network)
target_compile_definitions(nox-home PRIVATE NOX_HOME_DATA_DIR="${CMAKE_INSTALL_PREFIX}/share/nox-home")

install(TARGETS nox-home RUNTIME DESTINATION bin)
install(DIRECTORY apps/ DESTINATION share/nox-home/apps)
