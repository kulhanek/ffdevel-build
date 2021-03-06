# ==============================================================================
# FFDevel
# ==============================================================================

CMAKE_MINIMUM_REQUIRED(VERSION 2.8 FATAL_ERROR)
#SET(CMAKE_VERBOSE_MAKEFILE ON)
PROJECT(FFDevelBuild)

# ==============================================================================
# conditional setup ------------------------------------------------------------
# ==============================================================================

# target architecture: allowed values are: em64t
SET(TARGET_ARCHITECTURE em64t)

# ==============================================================================
# project setup ----------------------------------------------------------------
# ==============================================================================

# what languages we use ---------------------------
ENABLE_LANGUAGE(C)
ENABLE_LANGUAGE(CXX)
ENABLE_LANGUAGE(Fortran)

# this is composite project ----------------------
SET(COMPOSITE_PROJECT TRUE)
SET(DEVELOPMENT_ROOT "${CMAKE_BINARY_DIR}/src")

# extra options ----------------------------------
SET(TRY_QT_LIB              OFF CACHE BOOL "QT is not neccessary" FORCE)
SET(LIBS_COMPLEX            OFF CACHE BOOL "Support for complex numbers?" FORCE)

# ==============================================================================
# libraries --------------------------------------------------------------------
# ==============================================================================

# try to find math kernel library
SET(MKL_HOME "$ENV{MKL_HOME}")

IF(MKL_HOME)
    SET(MKL_FOUND TRUE)
    INCLUDE_DIRECTORIES(${MKL_HOME}/include)
    IF(TARGET_ARCHITECTURE STREQUAL i686)
        # NOT SUPPORTED
        SET(MKL_LIBS mkl_intel mkl_sequential mkl_core pthread)
    ELSEIF(TARGET_ARCHITECTURE STREQUAL em64t)
        LINK_DIRECTORIES(${MKL_HOME}/lib/intel64)
        SET(MKL_LIBS mkl_intel_lp64 mkl_sequential mkl_core pthread)
    ELSE(TARGET_ARCHITECTURE STREQUAL i686)
        MESSAGE(FATAL_ERROR "ERROR: Unsupported target architecture: ${TARGET_ARCHITECTURE}")
    ENDIF(TARGET_ARCHITECTURE STREQUAL i686)
ENDIF(MKL_HOME)

LINK_DIRECTORIES(${CMAKE_BINARY_DIR}/lib)
LINK_DIRECTORIES(${CMAKE_BINARY_DIR}/lib/drivers)

# ==============================================================================
# rpaths -----------------------------------------------------------------------
# ==============================================================================

# intel core and QT libraries
SET(INTEL_CORE_HOME "$ENV{INTEL_CORE_HOME}")

# use, i.e. don't skip the full RPATH for the build tree
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)

# when building, don't use the install RPATH already
# (but later on when installing)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE) 

# the RPATH to be used when installing
SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")

IF(INTEL_CORE_HOME)
    MESSAGE("-- INTEL_CORE_HOME: ${INTEL_CORE_HOME}")
    SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}:${INTEL_CORE_HOME}")
ENDIF(INTEL_CORE_HOME)

# add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

# ==============================================================================
# compiler setups --------------------------------------------------------------
# ==============================================================================

# C options
SET(CMAKE_C_FLAGS_RELEASE "-O2 -m64 -std=c11")
SET(CMAKE_C_FLAGS_DEBUG "-g -m64 -Wall -Werror -pedantic-errors -Wundef -Wno-long-long")

# C++ options
SET(CMAKE_CXX_FLAGS_RELEASE "-O2 -m64 -std=c++11")
SET(CMAKE_CXX_FLAGS_DEBUG "-O0 -m64 -g -Wall -Werror -pedantic-errors -Wundef -Wno-long-long")

# default compiler setups - gfortran
SET(CMAKE_Fortran_FLAGS_RELEASE "-O3 -fopenmp")
SET(CMAKE_Fortran_FLAGS_DEBUG   "-g -O0 -fcheck=all -ffpe-trap=invalid,zero,overflow -fopenmp -Wall")

# ifort
IF(FCOMP_NAME STREQUAL ifort)
    SET(CMAKE_Fortran_FLAGS_RELEASE "-O3 -fopenmp")
    SET(CMAKE_Fortran_FLAGS_DEBUG   "-g -O0 -std03 -traceback -check all -warn all")
ENDIF(FCOMP_NAME STREQUAL ifort)

SET(CMAKE_BUILD_TYPE Release)
#SET(CMAKE_BUILD_TYPE Debug)

# ==============================================================================
# project subdirectories  ------------------------------------------------------
# ==============================================================================

# thirdparty ---------------------------------------
IF(NOT MKL_FOUND)
    ADD_SUBDIRECTORY(src/thirdparty/blas/netlib)
    ADD_SUBDIRECTORY(src/thirdparty/lapack/3.1.1)
ENDIF(NOT MKL_FOUND)
ADD_SUBDIRECTORY(src/thirdparty/lbfgs/1.0)
ADD_SUBDIRECTORY(src/thirdparty/ranlux/1.0)
ADD_SUBDIRECTORY(src/thirdparty/nlopt/2.4.2)
ADD_SUBDIRECTORY(src/thirdparty/obcore/2.4.0)
ADD_SUBDIRECTORY(src/thirdparty/netcdfcore/4.0.1)
ADD_SUBDIRECTORY(src/thirdparty/shark-ml/4.0.0)

# projects ---------------------------------------
ADD_SUBDIRECTORY(src/projects/hipoly/1.0)
ADD_SUBDIRECTORY(src/projects/scimafic/1.0)
ADD_SUBDIRECTORY(src/projects/prmfile/1.0)
ADD_SUBDIRECTORY(src/projects/asl/2.0)
ADD_SUBDIRECTORY(src/projects/ffdevel/1.0)

# ==============================================================================
# inter-project dependencies  -------------------------------------------------
# ==============================================================================
ADD_DEPENDENCIES(cscimafic_shared hipoly_shared)
ADD_DEPENDENCIES(cprmfile_shared hipoly_shared)
ADD_DEPENDENCIES(asl_shared hipoly_shared cscimafic_shared cnetcdf_shared)
ADD_DEPENDENCIES(ffdevel_shared asl_shared fprmfile_shared fscimafic_shared shark flbfgs90_shared)

IF(NOT MKL_FOUND)
    # local blas and lapack
    ADD_DEPENDENCIES(flapackd_shared fblasd_shared)
    ADD_DEPENDENCIES(cscimafic_shared flapackd_shared)
    ADD_DEPENDENCIES(fscimafic_shared flapackd_shared)
    ADD_DEPENDENCIES(flbfgs90_shared flapackd_shared)
ENDIF(NOT MKL_FOUND)

