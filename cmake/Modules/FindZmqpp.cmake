mark_as_advanced(ZMQPP_LIBRARY ZMQPP_INCLUDE_DIR)

find_library(ZMQPP_LIBRARY NAMES zmqpp REQUIRED)
find_path(ZMQPP_INCLUDE_DIR NAMES zmqpp.hpp PATH_SUFFIXES zmqpp REQUIRED)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Zmqpp DEFAULT_MSG ZMQPP_LIBRARY ZMQPP_INCLUDE_DIR)
