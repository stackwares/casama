cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Load the system unwinder (libgcc_s) before the Flutter engine. libflutter_linux_gtk.so exports
# its own _Unwind_* functions, and when a plugin's C++ `throw` binds to those, the exception can't
# reach the plugin's own `catch` and the app aborts ("terminate called after throwing an instance
# of 'LibsecretError'" from flutter_secure_storage on a desktop without a Secret Service). Listed
# first, libgcc_s wins the symbol lookup for every library.
target_link_options(${BINARY_NAME} BEFORE PRIVATE "LINKER:--push-state,--no-as-needed,-lgcc_s,--pop-state")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
