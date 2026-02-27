# Toolchain file for G4 platform

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Specify the cross-compiler
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_AR arm-none-eabi-ar)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP arm-none-eabi-objdump)
set(CMAKE_SIZE arm-none-eabi-size)

# Set compiler flags for G4
set(CMAKE_C_FLAGS_INIT
    "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -ffunction-sections -fdata-sections"
)
set(CMAKE_CXX_FLAGS_INIT
    "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -ffunction-sections -fdata-sections"
)
set(CMAKE_ASM_FLAGS_INIT
    "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard"
)

# Set linker flags
set(CMAKE_EXE_LINKER_FLAGS_INIT
    "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -specs=nano.specs -specs=nosys.specs -Wl,--gc-sections -Wl,--print-memory-usage"
)

# Set the root path for finding libraries and includes
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Don't try to test the compiler
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

# STM32G4-specific definitions
add_definitions(-DSTM32G4)
add_definitions(-DUSE_HAL_DRIVER)
add_definitions(-DLOG_MODULE_SECTION=\".data.log_modules\")


# Function to generate binary and hex files
function(add_firmware_targets TARGET_APP)
    # Generate .bin file
    add_custom_command(TARGET ${TARGET_APP} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${TARGET_APP}> ${TARGET_APP}.bin
        COMMENT "Generating binary file"
    )

    # Generate .hex file
    add_custom_command(TARGET ${TARGET_APP} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${TARGET_APP}> ${TARGET_APP}.hex
        COMMENT "Generating hex file"
    )

    # Display size information
    add_custom_command(TARGET ${TARGET_APP} POST_BUILD
        COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${TARGET_APP}>
        COMMENT "Displaying size information"
    )
endfunction()

message(STATUS "Using STM32G4 toolchain")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  CXX Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "  MCU: Cortex-M4 with FPU")
