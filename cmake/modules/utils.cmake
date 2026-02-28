
# Macro to add source files - supports two modes:
# add_src(filename) - always adds the file
# add_src(variant, filepath) - conditionally adds based on variant
macro(add_src)
    # Check number of arguments
    if(${ARGC} EQUAL 1)
        # Simple mode: always add the file
        list(APPEND STM32_SOURCES "${ARGV0}")
        # message(STATUS "Added source: ${ARGV0}")
    elseif(${ARGC} EQUAL 2)
        # Conditional mode: add based on variant
        set(variant "${ARGV0}")
        set(filepath "${ARGV1}")
        set(should_add FALSE)

        # Check if variant is "all" - always add
        if("${variant}" STREQUAL "all")
            set(should_add TRUE)
        else()
            # Check specific variant exist in list of available variants
            list(FIND STM32_AVAILABLE_VARIANTS "${variant}" variant_index)
            if(variant_index EQUAL -1)
                message(FATAL_ERROR "add_src: Unknown variant '${variant}'. Available variants: ${STM32_AVAILABLE_VARIANTS}")
            endif()
            # Check if the variant matches any of the target variants
            list(FIND STM32_VARIANTS "${variant}" variant_index)
            if(NOT variant_index EQUAL -1)
                set(should_add TRUE)
            endif()
        endif()

        # Check if the file exists (even if not adding, to catch typos)
        get_filename_component(full_path "${filepath}" ABSOLUTE)
        if(NOT EXISTS "${full_path}")
            message(FATAL_ERROR "add_src: File '${filepath}' does not exist (resolved to: ${full_path}).")
        endif()

        # Add the file to STM32_SOURCES if condition is met
        if(should_add)
            list(APPEND STM32_SOURCES "${filepath}")
            # message(STATUS "Added source: ${filepath} (${variant_name}=${variant})")
        endif()
    else()
        message(FATAL_ERROR "add_src: Invalid number of arguments (${ARGC}). Use add_src(filename) or add_src(variant, filepath)")
    endif()
endmacro()

# Macro to include the specific variants files
macro(include_variant_file)
    # Iterate over STM32_VARIANTS
    foreach(variant IN LISTS STM32_VARIANTS)
        set(variant_file "${CMAKE_CURRENT_LIST_DIR}/cmake/modules/variants/${variant}.cmake")
        if(EXISTS "${variant_file}")
            message(STATUS "Include variant file: ${variant_file}")
            include("${variant_file}")
        else()
            message(STATUS "Variant file not found: ${variant_file}")
        endif()
    endforeach()
endmacro()

# Macro to include the specific variants post-configuration files
# This should be called after the executable is created
macro(include_variant_post_file)
    # Iterate over STM32_VARIANTS
    foreach(variant IN LISTS STM32_VARIANTS)
        set(variant_post_file "${CMAKE_CURRENT_LIST_DIR}/cmake/modules/variants/${variant}_post.cmake")
        if(EXISTS "${variant_post_file}")
            message(STATUS "Include variant post file: ${variant_post_file}")
            include("${variant_post_file}")
        else()
            message(VERBOSE "Variant post file not found: ${variant_post_file}")
        endif()
    endforeach()
endmacro()

# Macro to add a library to link
# Usage: add_lib_link(library_name)
macro(add_lib_link library_name)
    # Add the library to the list
    list(APPEND STM32_LINK_LIBS "${library_name}")
    message(STATUS "Added link library: ${library_name}")
endmacro()

# Function to check if a variant is enabled
function(is_variant_enabled variant result_var)
    list(FIND STM32_VARIANTS "${variant}" variant_index)
    if(NOT variant_index EQUAL -1)
        set(${result_var} TRUE PARENT_SCOPE)
    else()
        set(${result_var} FALSE PARENT_SCOPE)
    endif()
endfunction()
