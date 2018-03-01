#
# This file will help you to integrate a Radon CMake framework based project into your project.
# http://www.radonframework.org/projects/rf/wiki/UserManualCMakeFramework
# http://www.radonframework.org/projects/rf/wiki/DeveloperManualCMakeFramework
#
# It will be included by extern/Integrate.cmake 
# and move most of the configuration into Radon CMake framework scope.
#

# Obtain Radon CMake framework root path to call the other scripts from there.
# At this point the projectid is not set yet but the name of the cmake project
# is available and all macros called in it's scope. 
set(RCF_PATH "${CMAKE_CURRENT_LIST_DIR}/..")

cmake_policy(SET CMP0057 NEW)

get_property(checkRepo GLOBAL PROPERTY RCF_REPO_CHECK)
if(NOT DEFINED checkRepo)
    message(STATUS "Check for newest version of Radon CMake framework.")
    execute_process(COMMAND "${GIT_EXECUTABLE}" "pull" "-q"
                    WORKING_DIRECTORY "${RCF_PATH}")
    set_property(GLOBAL PROPERTY RCF_REPO_CHECK true)
endif()
# The following includes are the only exception where an other variable than
# ${${projectid}_LOCATION} is used to access files of the framework.
include("${RCF_PATH}/util/CMakeFunctionShortcut.cmake")
include("${RCF_PATH}/util/Macros.cmake")
include("${RCF_PATH}/intern/FileVersionSystem.cmake")
include("${RCF_PATH}/intern/Download.cmake")
include("${RCF_PATH}/extern/Integrate.cmake")
include("${RCF_PATH}/intern/SystemInfo.cmake")
include("${RCF_PATH}/intern/PackageManagement.cmake")

rcf_getsysteminfos()

macro(rcf_addlocation projectid protocol location)
	set(${projectid}_Locations ${${projectid}_Locations} "${protocol} ${location}")
endmacro()

macro(rcf_getlocations projectid locations)
	set(locations ${${projectid}_Locations})
endmacro()

macro(ConfigureProject projectid path)
	set(${projectid}_LOCATION "${path}")
	set(${projectid}_PUBLIC_INCLUDES "" CACHE INTERNAL "include directories")
	if ((DEFINED ${projectid}_FINALIZED AND NOT ${${projectid}_FINALIZED}) OR
		NOT DEFINED ${projectid}_FINALIZED)
		rcf_add_subdirectory_once(${${projectid}_LOCATION} "${PROJECT_BINARY_DIR}/${projectid}/")
	endif()
endmacro()

# everything went right :)
macro(FoundProject projectid projectname path)
	message(STATUS "Found ${projectname}")
	mark_as_advanced(${projectid}_DIR)
	set(${projectid}_FOUND ON)
	mark_as_advanced(${projectid}_FOUND)
	ConfigureProject(${projectid} ${path})
endmacro()

# everything gone wrong :(
macro(NoProjectFound projectid projectname)
	set(${projectid}_FOUND OFF)
	mark_as_advanced(${projectid}_FOUND)
	message(FATAL_ERROR "Couldn't find or integrate ${projectname}. Please use ${projectid}_DIR to specify the location.")
endmacro()

# first try failed this is the backup
macro(FailSafe projectid projectname)
	if(NOT DEFINED ${projectid}_DIR)
		set(${projectid}_DIR "-NOTFOUND" CACHE PATH "Path to ${projectname} directory.")
	endif()
	if(EXISTS "${${projectid}_DIR}")
		if(NOT IS_ABSOLUTE "${${projectid}_DIR}")
			get_filename_component(absolute_path "${CMAKE_BINARY_DIR}/${${projectid}_DIR}" ABSOLUTE)
			set(${projectid}_DIR "${absolute_path}" CACHE PATH "Path to ${projectname} directory." FORCE)
			message(STATUS "Convert relative path into a absolute one ${${projectid}_DIR}")
		endif()
		# on windows there are some cases where we have to encounter backslashes
		STRING(REGEX REPLACE "\\\\" "/" ${projectid}_DIR ${${projectid}_DIR}) 	
		FoundProject(${projectid} ${projectname} "${${projectid}_DIR}")
	else()
		NoProjectFound(${projectid} ${projectname})
	endif()
endmacro()

macro(rcf_obtain_project projectid outdir)
    set(outdir "")
    set (extra_macro_args ${ARGN})
    list(LENGTH extra_macro_args num_extra_args)
    if (${num_extra_args} GREATER 0)
        # specific revision of file version system
        list(GET extra_macro_args 0 GetSpecificVersion)
    endif()
    
	foreach(entry ${${projectid}_Locations})
		separate_arguments(entry)
		list(GET entry 0 protocol)
		list(GET entry 1 location)
		if(${protocol} STREQUAL "file")
			if(EXISTS "${location}")
				set(outdir ${location})
			else()
				message(AUTHOR_WARNING "${projectname} '${location}' doesn't exists !")
			endif()
		elseif(${protocol} STREQUAL "env")
			if(EXISTS "$ENV{${location}}/")
				set(outdir "$ENV{${location}}/")
			else()
				message(AUTHOR_WARNING "Add user or system environment variable ${environmentname} !")
			endif()
		elseif(${protocol} STREQUAL "download")
			rcf_download(${location} ${projectid} outdir)
		else()#file version system
            if(DEFINED GetSpecificVersion)
                rfc_getreporevision(${location} ${protocol} ${projectid} ${GetSpecificVersion} outdir)                
                unset(GetSpecificVersion)
            else()
                rcf_getrepo(${location} ${protocol} ${projectid} outdir)            
            endif()
		endif()
		
		if(EXISTS ${outdir})
			break()
		endif()
	endforeach()
    
    if(${outdir} STREQUAL "")
        MESSAGE(FATAL_ERROR "Could not find an entry for ${projectid}! Use rcf_addlocation(${projectid} ...).")
    endif()
endmacro()

# projectid = will be used as pre-name for all variables
# projectname = will be used as output in the option description
# environmentname = will be used as key for the search in the environment variables
macro(Integrate projectid projectname environmentname)
	# check if initialization order is valid
    get_property(finalized GLOBAL PROPERTY "${projectid}_FINALIZED")

	if(DEFINED ${projectid}_FOUND AND "${finalized}" STREQUAL "")
		message(FATAL_ERROR "${projectname} is involved in an circular dependency. Please track the project which call Integrate() for ${projectname} and move it behind Finalize().")
	endif()
	
	if(NOT DEFINED ${projectid}_FOUND)
		option(${projectid}_USE "Include ${projectname} into the project." ON)	
		
		if(${projectid}_USE)
			message(STATUS "Integrate ${projectid}:")
			set(outdir "")
			rcf_obtain_project(${projectid} outdir)
			if(EXISTS ${outdir})
				FoundProject(${projectid} ${projectname} ${outdir})
			else()
				FailSafe(${projectid} ${projectname})
			endif()			
		endif()
	endif()

	string(REGEX MATCH "${${projectid}_NAME}" match "${RCF_INTEGRATED}")
	if ("${match}" STREQUAL "")
		set(RCF_INTEGRATED "${${projectid}_NAME} ${RCF_INTEGRATED}" CACHE INTERNAL "Integrated projects")	
	endif()	
	include_directories(${${projectid}_PUBLIC_INCLUDES})
endmacro()