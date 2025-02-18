project(bsr)
cmake_minimum_required(VERSION 3.13)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)
set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mods)
include_directories(${CMAKE_Fortran_MODULE_DIRECTORY})

enable_language(Fortran)

if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RELEASE CACHE STRING
    "Choose the type of build, options are: None Debug Release."
    FORCE)
endif (NOT CMAKE_BUILD_TYPE)

get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)

if (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  # gfortran
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-automatic -fcray-pointer -fno-f2c -O2 -fallow-argument-mismatch")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g")
elseif (Fortran_COMPILER_NAME MATCHES "ifort.*")
  # ifort (untested)
  set (CMAKE_Fortran_FLAGS_RELEASE "-f77rtl -O2")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-f77rtl -O0 -g")
elseif (Fortran_COMPILER_NAME MATCHES "g77")
  # g77
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O2 -m32")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g -m32")
else (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  message ("CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
  message ("Fortran compiler: " ${Fortran_COMPILER_NAME})
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  set (CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-O0 -g")
endif (Fortran_COMPILER_NAME MATCHES "gfortran.*")

set(CMAKE_CXX_FLAGS "--std=c++11 -Wall -Wextra")
if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
else()
  set(CMAKE_BUILD_TYPE "Debug")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g")
  add_definitions("-DDEBUG")
endif()

find_package(BLAS)
find_package(LAPACK)
find_package(MPI)
if(${MPI_Fortran_FOUND})
  find_package(SCALAPACK)
  find_library(SCALAPACK NAMES scalapack libscalapack ScaLAPACK SCALAPACK HINTS /projects/spack/opt/spack/linux-centos8-zen/gcc-8.3.1/netlib-scalapack-2.1.0-7tk5kwnkegac25q4kx6un3agy2vpqkvg/lib/cmake/scalapack-2.1.0 REQUIRED)
  message("MPI implementation found, enabling build of MPI executables")
  if(${SCALAPACK_FOUND})
    message("MPI and Scalapack foudn - enabling MPI Fortran")
    include_directories(${MPI_Fortran_INCLUDE_PATH})
  endif()
endif()

set(FC_MALLOC LINUX)
set(BLAS_LAPACK_LIBRARIES ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES})

add_subdirectory(libs)
add_subdirectory(bsr)
add_subdirectory(dbsr)
