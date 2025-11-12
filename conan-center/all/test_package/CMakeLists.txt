cmake_minimum_required(VERSION 3.14)
project(NekoLogTest CXX)

find_package(NekoLog REQUIRED CONFIG)

add_executable(test_nekolog test_nekolog.cpp)
target_link_libraries(test_nekolog PRIVATE Neko::Log)
target_compile_features(test_nekolog PRIVATE cxx_std_20)

enable_testing()
add_test(NAME test_nekolog COMMAND test_nekolog)
