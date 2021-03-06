#[[.rst Recast navigation
=================
]]
set(package_protocol "git")
set(package_source "https://github.com/recastnavigation/recastnavigation.git")

if(${package_version} STREQUAL "dev")
elseif(${package_version} STREQUAL "newest" OR ${package_version} STREQUAL "1.5.1")
  set(package_revision "f14896eb207b593e66ccc5762918eda0b4237516")
else()
  message(FATAL_ERROR "Unknown package version. Please use 'dev','newest' or '1.5.1'.")
endif()

function(build_package location)
  rcf_generate(module DEBUGUTILS DebugUtils "3rd Party Libraries/recast")
  rcf_add_recursive("${location}/DebugUtils/Source" "Source")
  AddPublicInclude(DEBUGUTILS "${location}/DebugUtils/Include")
  include_directories("${location}/Detour/Include" "${location}/DetourTileCache/Include" "${location}/Recast/Include")
  rcf_endgenerate()

  rcf_generate(module DETOUR Detour "3rd Party Libraries/recast")
  rcf_add_recursive("${location}/Detour/Source" "Source")
  AddPublicInclude(DETOUR "${location}/Detour/Include")
  rcf_endgenerate()

  rcf_generate(module DETOURCROWD DetourCrowd "3rd Party Libraries/recast")
  rcf_add_recursive("${location}/DetourCrowd/Source" "Source")
  AddPublicInclude(DETOURCROWD "${location}/DetourCrowd/Include")
  include_directories("${location}/Detour/Include" "${location}/Recast/Include")
  rcf_endgenerate()

  rcf_generate(module DETOURTILECACHE DetourTileCache "3rd Party Libraries/recast")
  rcf_add_recursive("${location}/DetourTileCache/Source" "Source")
  AddPublicInclude(DETOURTILECACHE "${location}/DetourTileCache/Include")
  include_directories("${location}/Detour/Include" "${location}/Recast/Include")
  rcf_endgenerate()

  rcf_generate(module RECAST Recast "3rd Party Libraries/recast")
  rcf_add_recursive("${location}/Recast/Source" "Source")
  AddPublicInclude(RECAST "${location}/Recast/Include")
  rcf_endgenerate()
endfunction()