# 🚀 MODERN CMAKE: Create an interface library to encapsulate threading logic.
# This prevents polluting the global scope with definitions and libraries.
add_library(threading_config INTERFACE)

# ------------------------------------------------------------------------------
# 1. OPENMP CONFIGURATION
# ------------------------------------------------------------------------------
if(MULTITHREADING)
    find_package(OpenMP REQUIRED)
    message(STATUS "Multithreading is enabled (OpenMP).")
    
    # 🛡️ ENCAPSULATION: Only link OpenMP to targets that link 'threading_config'.
    target_link_libraries(threading_config INTERFACE OpenMP::OpenMP_CXX)
else()
    message(STATUS "Multithreading is disabled.")
    
    # ⚡ DEFINITIONS: Pass flags only to consumers of this config.
    # -DNO_MULTITHREADING: Custom flag likely used in your code.
    # -DBOOST_SP_NO_ATOMIC_ACCESS: Disables atomic ref-counting in Boost (perf boost for single-thread).
    target_compile_definitions(threading_config INTERFACE 
        NO_MULTITHREADING 
        BOOST_SP_NO_ATOMIC_ACCESS
    )
endif()

# ------------------------------------------------------------------------------
# 2. INTEL TBB CONFIGURATION
# ------------------------------------------------------------------------------
if(DISABLE_TBB)
    message(STATUS "Intel Thread Building Blocks is disabled (Explicitly).")
    target_compile_definitions(threading_config INTERFACE NO_TBB)
else()
    # QUIET is good, but we need to ensure we actually link it if found.
    find_package(TBB QUIET OPTIONAL_COMPONENTS tbb)
    
    if(TBB_FOUND)
        message(STATUS "Intel Thread Building Blocks is enabled.")
        
        # 🛡️ LINKING FIX: Actually link TBB! 
        # Modern TBB CMake config exports 'TBB::tbb'.
        if(TARGET TBB::tbb)
            target_link_libraries(threading_config INTERFACE TBB::tbb)
        else()
            # Fallback for older FindTBB modules that rely on variables
            target_include_directories(threading_config INTERFACE ${TBB_INCLUDE_DIRS})
            target_link_libraries(threading_config INTERFACE ${TBB_LIBRARIES})
        endif()
    else()
        message(STATUS "Could not locate TBB (Disabled).")
        target_compile_definitions(threading_config INTERFACE NO_TBB)
    endif()
endif()
