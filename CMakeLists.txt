# @file CMakeLists.txt
# @brief CMake configuration for the stm32 template project
# @author Cyprien Ménard
# @date 23/02/2026

cmake_minimum_required(VERSION 3.20)


if(NOT DO_NOT_USE_LOCAL_CMAKE)
    include(cmake/local.cmake OPTIONAL)
endif()

project(${EXECUTABLE_NAME} VERSION 1.0.0 LANGUAGES C CXX ASM)

# Set C standard
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set compiler warnings for project source files only
set(STM32_COMPILE_WARNINGS
    -Wall # Enable all common warnings
    -Wextra # Enable extra warnings
    -Werror # Treat warnings as errors
    -Wshadow # Warn about variable shadowing
    -Wformat=2 # Warn about format string vulnerabilities
    -Wuninitialized # Warn about uninitialized variables
    $<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes> # Warn about missing prototypes (C only)
    $<$<COMPILE_LANGUAGE:C>:-Wmissing-prototypes> # Warn about missing function prototypes (C only)
    -Wconversion # Warn about implicit conversions
    -Wsign-conversion # Warn about sign conversions
    -Wnull-dereference # Warn about potential null dereferences
    -Wdouble-promotion # Warn about float to double promotions
    -Wcast-align # Warn about pointer casts with increased alignment
    -Wundef # Warn about undefined macros in #if
    -Wno-format-nonliteral # Disable warning about non-literal format strings
    -fstack-protector-strong
)

# Set output directories: We catch all variables: used by vscode extensions to locate binaries
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "Runtime output directory" FORCE)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "Library output directory" FORCE)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "Archive output directory" FORCE)

# Set software package (SWP) root directory
set(SWP_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cmake/swp)

# Include modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
include(utils)
include(variants)
include(cubemx)

set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type" FORCE)

# init app sources list
set(STM32_CMAKE_TARGET ${EXECUTABLE_NAME})
set(STM32_SOURCES "")


# Main application file
add_src("src/main.c")

# Parse the base variants into variants
set(STM32_VARIANTS ${STM32_BASE_VARIANTS})
message(VERBOSE "Selected base variants : ${STM32_VARIANTS}")

# Check if BSP is specified BEFORE loading SWP modules (needed for conditional source inclusion)
if(DEFINED STM32_BSP_NAME AND NOT "${STM32_BSP_NAME}" STREQUAL "")
    set(STM32_USE_BSP TRUE)
    message(STATUS "BSP mode enabled: ${STM32_BSP_NAME}")
endif()

# Generate CubeMX BSP BEFORE including variants (needed for CMSIS-DSP and other dependencies)
if(STM32_USE_BSP)
    message(STATUS "Pre-generating CubeMX BSP: ${STM32_BSP_NAME}")

    # Add compile definition
    list(APPEND STM32_COMPILE_DEFINITIONS STM32_USE_BSP)

    # Generate CubeMX code (this exports BSP_CMSIS_INCLUDE_DIR)
    generate_cubemx_code(${STM32_BSP_NAME})
endif()

# Include specific variants cmake files (may use BSP_CMSIS_INCLUDE_DIR for CMSIS-DSP)
include_variant_file()

# add driver sources recursively
list(LENGTH STM32_SOURCES STM32_SOURCE_COUNT)
message(STATUS "Creating executable ${STM32_CMAKE_TARGET} with ${STM32_SOURCE_COUNT} source files.")
# Create the STM32 executable with all collected sources
add_executable(${STM32_CMAKE_TARGET} ${STM32_SOURCES})

# Include generated BSP code in the target (if BSP was generated above)
if(STM32_USE_BSP)
    message(STATUS "Including CubeMX BSP in target: ${STM32_BSP_NAME}")
    include_generated_cubemx(${STM32_CMAKE_TARGET} ${STM32_BSP_NAME})
endif()
# Apply strict warnings only to our source files (not other libraries)
get_target_property(STM32_TARGET_SOURCES ${STM32_CMAKE_TARGET} SOURCES)
foreach(source_file ${STM32_TARGET_SOURCES})
    get_filename_component(source_abs ${source_file} ABSOLUTE)
    if(source_abs MATCHES "^${CMAKE_SOURCE_DIR}/src/" OR source_abs MATCHES "^${CMAKE_SOURCE_DIR}/tests/")
        # Compile options are generator-expression aware
        set_source_files_properties(${source_file} PROPERTIES
            COMPILE_OPTIONS "${STM32_COMPILE_WARNINGS}"
        )
    endif()
endforeach()

# Include post-variant configuration files (for variant-specific linking)
include_variant_post_file()

# Add external dependencies to target
if(DEFINED STM32_EXTERNAL_DEPENDENCIES AND NOT "${STM32_EXTERNAL_DEPENDENCIES}" STREQUAL "")
    add_dependencies(${STM32_CMAKE_TARGET} ${STM32_EXTERNAL_DEPENDENCIES})
    message(STATUS "Added external dependencies: ${STM32_EXTERNAL_DEPENDENCIES}")
endif()

# Apply linker script if provided by variant (e.g., STM32G4)
if(DEFINED STM32G4_LINKER_SCRIPT)
    target_link_options(${STM32_CMAKE_TARGET} PRIVATE -u _printf_float -T${STM32G4_LINKER_SCRIPT})
    message(STATUS "Applied linker script: ${STM32G4_LINKER_SCRIPT}")
endif()

# Link necessary libraries
target_link_libraries(${STM32_CMAKE_TARGET} PRIVATE m)
if(DEFINED STM32_LINK_LIBS AND NOT "${STM32_LINK_LIBS}" STREQUAL "")
    message(STATUS "Linking libraries: ${STM32_LINK_LIBS}")
    target_link_libraries(${STM32_CMAKE_TARGET} PRIVATE ${STM32_LINK_LIBS})
endif()

# Set preprocessor definitions
if(DEFINED STM32_COMPILE_DEFINITIONS)
    message(STATUS "Setting compile definitions: ${STM32_COMPILE_DEFINITIONS}")
    target_compile_definitions(${STM32_CMAKE_TARGET} PRIVATE ${STM32_COMPILE_DEFINITIONS})
endif()

# Set base include directories
if(DEFINED STM32_PRIORITY_INCLUDES)
    target_include_directories(${STM32_CMAKE_TARGET} BEFORE PRIVATE ${STM32_PRIORITY_INCLUDES})
endif()
target_include_directories(${STM32_CMAKE_TARGET} PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_include_directories(${STM32_CMAKE_TARGET} PRIVATE ${STM32_INCLUDE_DIRS})
