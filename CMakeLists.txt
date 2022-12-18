cmake_minimum_required( VERSION 3.15)

project( mulle-genstrings C)



### mulle-sde environment

# add cmake module paths to search path
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/share")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/reflect")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake")

include( Environment)
include( Files)
include( Dependencies)

### Executable

# for some of the more funky filenames, cmake croaks so just copy the
# dox directory verbatim
include( Executable)
include( InstallExecutable)
include( FinalOutput OPTIONAL)

# only for Executable
include( Motd OPTIONAL)
