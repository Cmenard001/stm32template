# CubeMX code generation module
# This module handles automatic CubeMX code generation during build

# Find STM32CubeMX executable
find_program(CUBEMX_EXECUTABLE
    NAMES STM32CubeMX
    PATHS /usr/bin /usr/local/bin /opt/st/stm32cubemx
    DOC "Path to STM32CubeMX executable"
)

if(CUBEMX_EXECUTABLE)
    message(STATUS "Found STM32CubeMX: ${CUBEMX_EXECUTABLE}")
else()
    message(WARNING "STM32CubeMX not found. CubeMX code generation will be skipped.")
endif()

# Function to generate CubeMX code for a BSP
# Usage: generate_cubemx_code(BSP_NAME)
function(generate_cubemx_code BSP_NAME)
    # Skip generation if CubeMX is not available
    if(NOT CUBEMX_EXECUTABLE)
        message(WARNING "Skipping CubeMX generation for ${BSP_NAME}: STM32CubeMX not found")
        return()
    endif()

    set(BSP_SOURCE_DIR "${CMAKE_SOURCE_DIR}/src/bsp/${BSP_NAME}")
    set(BSP_BUILD_DIR "${CMAKE_BINARY_DIR}/drivers/${BSP_NAME}")
    set(IOC_FILE "${BSP_SOURCE_DIR}/${BSP_NAME}.ioc")

    # Check if .ioc file exists
    if(NOT EXISTS "${IOC_FILE}")
        message(FATAL_ERROR "CubeMX .ioc file not found: ${IOC_FILE}")
    endif()

    # Create build directory for BSP
    file(MAKE_DIRECTORY "${BSP_BUILD_DIR}")

    # Create CubeMX command script
    set(CUBEMX_SCRIPT "${CMAKE_BINARY_DIR}/cubemx_gen_${BSP_NAME}.txt")
    file(WRITE "${CUBEMX_SCRIPT}" "project generate\nexit\n")

    # Create a hash file to track generation
    set(IOC_HASH_FILE "${BSP_BUILD_DIR}/.ioc_hash")

    # Calculate hash of the IOC file
    file(MD5 "${IOC_FILE}" CURRENT_IOC_HASH)

    # Check if regeneration is needed
    set(NEED_REGENERATION FALSE)
    if(EXISTS "${IOC_HASH_FILE}")
        file(READ "${IOC_HASH_FILE}" LAST_IOC_HASH)
        if(NOT "${LAST_IOC_HASH}" STREQUAL "${CURRENT_IOC_HASH}")
            set(NEED_REGENERATION TRUE)
        endif()
    else()
        set(NEED_REGENERATION TRUE)
    endif()

    # Check if code already exists
    if(NOT EXISTS "${BSP_BUILD_DIR}/Core" OR NEED_REGENERATION)
        message(STATUS "Generating CubeMX code for ${BSP_NAME}...")
        message(STATUS "  Input:  ${IOC_FILE}")
        message(STATUS "  Output: ${BSP_BUILD_DIR}")

        # If IOC file changed, clean old generated code
        if(NEED_REGENERATION AND EXISTS "${BSP_BUILD_DIR}/Core")
            message(STATUS "  IOC file changed - cleaning old generated code...")
            file(REMOVE_RECURSE "${BSP_BUILD_DIR}")
            file(MAKE_DIRECTORY "${BSP_BUILD_DIR}")
        endif()

        # Copy IOC file to build directory
        set(BUILD_IOC_FILE "${BSP_BUILD_DIR}/${BSP_NAME}.ioc")
        file(COPY "${IOC_FILE}" DESTINATION "${BSP_BUILD_DIR}")

        # Create CubeMX script in build directory
        set(BUILD_CUBEMX_SCRIPT "${BSP_BUILD_DIR}/mx_gen.txt")
        file(WRITE "${BUILD_CUBEMX_SCRIPT}"
            "config load ${BUILD_IOC_FILE}\n"
            "project couplefilesbyip 0\n"
            "project toolchain Makefile\n"
            "project path ${BSP_BUILD_DIR}\n"
            "project generate\n"
            "exit\n"
        )

        # Find xvfb-run for headless execution (used in CI/Docker)
        find_program(XVFB_RUN xvfb-run)

        # Prepare command
        if(XVFB_RUN)
            set(CUBEMX_COMMAND ${XVFB_RUN} -a ${CUBEMX_EXECUTABLE})
            message(STATUS "  CubeMX command: ${XVFB_RUN} -a ${CUBEMX_EXECUTABLE}")
        else()
            message(STATUS "  xvfb-run not found, running CubeMX directly")
            set(CUBEMX_COMMAND ${CUBEMX_EXECUTABLE})
            message(STATUS "  CubeMX command: ${CUBEMX_EXECUTABLE}")
        endif()

        # Debug: Check if all commands exist
        if(NOT EXISTS "${CUBEMX_EXECUTABLE}")
            message(FATAL_ERROR "CubeMX executable not found at: ${CUBEMX_EXECUTABLE}")
        endif()
        if(XVFB_RUN AND NOT EXISTS "${XVFB_RUN}")
            message(FATAL_ERROR "xvfb-run not found at: ${XVFB_RUN}")
        endif()

        # Print the shell command for debugging
        message(STATUS "Execute command: ${CUBEMX_COMMAND} -q \"${BUILD_CUBEMX_SCRIPT}\"")
        message(STATUS "  Script content:")
        file(READ "${BUILD_CUBEMX_SCRIPT}" _SCRIPT_CONTENT)
        message(STATUS "  ${_SCRIPT_CONTENT}")

        # Execute CubeMX
        execute_process(
            COMMAND ${CUBEMX_COMMAND} -q "${BUILD_CUBEMX_SCRIPT}"
            WORKING_DIRECTORY "${BSP_BUILD_DIR}"
            RESULT_VARIABLE CUBEMX_RESULT
            OUTPUT_VARIABLE CUBEMX_OUTPUT
            ERROR_VARIABLE CUBEMX_ERROR
            TIMEOUT 300
        )

        if(NOT CUBEMX_RESULT EQUAL 0)
            message(FATAL_ERROR "CubeMX generation failed for ${BSP_NAME}\nResult: ${CUBEMX_RESULT}\nOutput: ${CUBEMX_OUTPUT}\nError: ${CUBEMX_ERROR}")
        endif()

        # Save IOC file hash
        file(WRITE "${IOC_HASH_FILE}" "${CURRENT_IOC_HASH}")

        # Copy HAL driver sources from firmware repository (Makefile toolchain
        # only generates references, not copies)
        if(EXISTS "${BSP_BUILD_DIR}/Makefile")
            file(READ "${BSP_BUILD_DIR}/Makefile" _MK_CONTENT)
            # Extract all HAL source file references
            string(REGEX MATCHALL "Drivers/STM32[A-Za-z0-9]*_HAL_Driver/Src/[a-z0-9_]+\\.c" _HAL_REFS "${_MK_CONTENT}")
            foreach(_HAL_REF ${_HAL_REFS})
                # Extract just the filename
                get_filename_component(_HAL_FILE "${_HAL_REF}" NAME)
                # Extract the driver directory name
                string(REGEX MATCH "STM32[A-Za-z0-9]*_HAL_Driver" _HAL_DRIVER_DIR "${_HAL_REF}")
                set(_DST_DIR "${BSP_BUILD_DIR}/Drivers/${_HAL_DRIVER_DIR}/Src")
                # Find the source in the firmware repository
                file(GLOB_RECURSE _REPO_FILE "$ENV{HOME}/STM32Cube/Repository/*/Drivers/${_HAL_DRIVER_DIR}/Src/${_HAL_FILE}")
                if(_REPO_FILE)
                    list(GET _REPO_FILE 0 _REPO_FILE)
                    file(COPY "${_REPO_FILE}" DESTINATION "${_DST_DIR}")
                endif()
            endforeach()
            list(LENGTH _HAL_REFS _HAL_COUNT)
            message(STATUS "  Copied ${_HAL_COUNT} HAL driver sources from firmware repository")
        endif()

        # Copy startup file from firmware repository
        # Extract MCU name from IOC to find the correct startup file
        file(STRINGS "${IOC_FILE}" _MCU_LINE REGEX "^Mcu.UserName=")
        if(_MCU_LINE)
            string(REGEX REPLACE "^Mcu.UserName=STM32(.*)" "\\1" _MCU_SUFFIX "${_MCU_LINE}")
            string(TOLOWER "${_MCU_SUFFIX}" _MCU_SUFFIX_LOWER)
            file(GLOB_RECURSE _STARTUP_FILES "$ENV{HOME}/STM32Cube/Repository/*/Drivers/CMSIS/Device/ST/*/Source/Templates/gcc/startup_stm32${_MCU_SUFFIX_LOWER}.s")
            if(_STARTUP_FILES)
                list(GET _STARTUP_FILES 0 _STARTUP_SRC)
                file(COPY "${_STARTUP_SRC}" DESTINATION "${BSP_BUILD_DIR}")
                message(STATUS "  Copied startup file: startup_stm32${_MCU_SUFFIX_LOWER}.s")
            else()
                message(WARNING "  Startup file not found for MCU: STM32${_MCU_SUFFIX}")
            endif()
        endif()

        # Patch main.c: rename main() to bsp_init()
        # Makefile toolchain uses Src/ instead of Core/Src/
        set(MAIN_C_FILE "${BSP_BUILD_DIR}/Src/main.c")
        if(NOT EXISTS "${MAIN_C_FILE}")
            set(MAIN_C_FILE "${BSP_BUILD_DIR}/Core/Src/main.c")
        endif()
        if(EXISTS "${MAIN_C_FILE}")
            file(READ "${MAIN_C_FILE}" MAIN_CONTENT)

            # Rename main() to bsp_init()
            string(REPLACE "int main(void)" "void bsp_init(void)" MAIN_CONTENT "${MAIN_CONTENT}")
            string(REPLACE "@retval int" "@retval void" MAIN_CONTENT "${MAIN_CONTENT}")

            # Add return after /* USER CODE BEGIN 2 */ - keep Error_Handler and other code
            string(REPLACE "/* USER CODE BEGIN 2 */\n\n  /* USER CODE END 2 */\n\n  /* Infinite loop */" "/* USER CODE BEGIN 2 */\n  return; // BSP initialization complete, return to stm32 main()\n  /* USER CODE END 2 */\n\n  /* Infinite loop removed - using stm32 main */" MAIN_CONTENT "${MAIN_CONTENT}")

            file(WRITE "${MAIN_C_FILE}" "${MAIN_CONTENT}")
            message(STATUS "  Patched main.c -> bsp_init()")
        endif()

        # Patch linker script: add project-specific sections
        file(GLOB LINKER_SCRIPT_FILE "${BSP_BUILD_DIR}/*.ld")
        if(LINKER_SCRIPT_FILE)
            list(GET LINKER_SCRIPT_FILE 0 LD_FILE)
            file(READ "${LD_FILE}" LD_CONTENT)

            file(WRITE "${LD_FILE}" "${LD_CONTENT}")
            message(STATUS "  Patched linker script for project-specific symbols")
        endif()

        message(STATUS "CubeMX code generated successfully for ${BSP_NAME}")
    else()
        message(STATUS "CubeMX code already up-to-date for ${BSP_NAME}")
    endif()

    # Export CMSIS include path for use by other libraries (e.g., CMSIS-DSP)
    set(BSP_CMSIS_INCLUDE_DIR "${BSP_BUILD_DIR}/Drivers/CMSIS/Include" PARENT_SCOPE)
    message(STATUS "  Exported CMSIS include directory: ${BSP_BUILD_DIR}/Drivers/CMSIS/Include")

endfunction()

# Function to include generated CubeMX code
# Usage: include_generated_cubemx(TARGET_NAME BSP_NAME)
function(include_generated_cubemx TARGET_NAME BSP_NAME)
    set(BSP_BUILD_DIR "${CMAKE_BINARY_DIR}/drivers/${BSP_NAME}")

    # Verify that Core directory exists
    # if(NOT EXISTS "${BSP_BUILD_DIR}/Core")
    #     message(FATAL_ERROR "CubeMX Core directory not found in ${BSP_BUILD_DIR}. Generation may have failed.")
    # endif()

    # Collect generated HAL driver sources
    file(GLOB_RECURSE HAL_SOURCES "${BSP_BUILD_DIR}/Drivers/STM32*_HAL_Driver/Src/*.c")
    # Exclude HAL driver template files (e.g., stm32g4xx_hal_msp_template.c)
    list(FILTER HAL_SOURCES EXCLUDE REGEX ".*_template\\.c$")

    # Collect Core sources - support both STM32CubeIDE (Core/Src/) and Makefile (Src/) layouts
    file(GLOB CORE_SOURCES "${BSP_BUILD_DIR}/Core/Src/*.c" "${BSP_BUILD_DIR}/Src/*.c")

    # Find startup file (check multiple possible locations)
    file(GLOB STARTUP_FILES
        "${BSP_BUILD_DIR}/startup_*.s"
        "${BSP_BUILD_DIR}/Core/Startup/startup_*.s"
        "${BSP_BUILD_DIR}/Startup/startup_*.s"
        "${BSP_BUILD_DIR}/*_FLASH.ld"
    )

    # Combine all sources
    set(ALL_BSP_SOURCES ${HAL_SOURCES} ${CORE_SOURCES} ${STARTUP_FILES})

    list(LENGTH ALL_BSP_SOURCES SOURCE_COUNT)
    if(SOURCE_COUNT EQUAL 0)
        message(FATAL_ERROR "No CubeMX sources found in ${BSP_BUILD_DIR}. Generation failed.")
    endif()

    message(STATUS "Including CubeMX generated code for ${BSP_NAME}")
    message(STATUS "  Found ${SOURCE_COUNT} source files")

    # C Flags for generated code - disable warnings for generated code
    target_compile_options(${TARGET_NAME} PRIVATE
        $<$<COMPILE_LANGUAGE:C>:-w>
    )

    # Add sources to target
    target_sources(${TARGET_NAME} PRIVATE ${ALL_BSP_SOURCES})

    # Extract MCU definition from IOC file to add as compile definition
    # Example: Mcu.Name=STM32F405RGTx -> STM32F405xx
    set(IOC_FILE "${CMAKE_SOURCE_DIR}/src/bsp/${BSP_NAME}/${BSP_NAME}.ioc")
    if(EXISTS "${IOC_FILE}")
        file(STRINGS "${IOC_FILE}" MCU_NAME_LINE REGEX "^Mcu.Name=")
        if(MCU_NAME_LINE)
            # Extract family+number (e.g., F405 from STM32F405RGTx)
            string(REGEX REPLACE "^Mcu.Name=STM32([A-Z][0-9]+).*" "STM32\\1xx" MCU_DEFINE "${MCU_NAME_LINE}")
            target_compile_definitions(${TARGET_NAME} PRIVATE ${MCU_DEFINE})
            message(STATUS "  MCU definition: ${MCU_DEFINE}")
        endif()
    endif()

    # Add include directories - support both STM32CubeIDE (Core/Inc/) and Makefile (Inc/) layouts
    target_include_directories(${TARGET_NAME} PRIVATE
        "${BSP_BUILD_DIR}/Core/Inc"
        "${BSP_BUILD_DIR}/Inc"
    )

    # Find and add HAL driver includes
    file(GLOB HAL_DRIVER_DIRS "${BSP_BUILD_DIR}/Drivers/STM32*_HAL_Driver")
    foreach(HAL_DIR ${HAL_DRIVER_DIRS})
        target_include_directories(${TARGET_NAME} PRIVATE
            "${HAL_DIR}/Inc"
            "${HAL_DIR}/Inc/Legacy"
        )
    endforeach()

    # Add CMSIS includes
    file(GLOB CMSIS_DEVICE_DIRS "${BSP_BUILD_DIR}/Drivers/CMSIS/Device/ST/STM32*")
    foreach(CMSIS_DIR ${CMSIS_DEVICE_DIRS})
        target_include_directories(${TARGET_NAME} PRIVATE
            "${CMSIS_DIR}/Include"
        )
    endforeach()

    target_include_directories(${TARGET_NAME} PRIVATE
        "${BSP_BUILD_DIR}/Drivers/CMSIS/Include"
    )

    # Export CMSIS include path for other libraries (e.g., CMSIS-DSP)
    set(BSP_CMSIS_INCLUDE_DIR "${BSP_BUILD_DIR}/Drivers/CMSIS/Include" PARENT_SCOPE)
    message(STATUS "  Exported CMSIS include path: ${BSP_BUILD_DIR}/Drivers/CMSIS/Include")

    # Find and set linker script
    file(GLOB LINKER_SCRIPT "${BSP_BUILD_DIR}/*.ld")
    if(LINKER_SCRIPT)
        list(GET LINKER_SCRIPT 0 LINKER_SCRIPT_FILE)
        set(STM32G4_LINKER_SCRIPT "${LINKER_SCRIPT_FILE}" PARENT_SCOPE)
        message(STATUS "  Using linker script: ${LINKER_SCRIPT_FILE}")
    else()
        message(FATAL_ERROR "No linker script found in ${BSP_BUILD_DIR}")
    endif()

endfunction()
