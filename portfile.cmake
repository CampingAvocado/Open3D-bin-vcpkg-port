# vcpkg checks and configs
if(NOT (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "amd64"))
    message(FATAL_ERROR "This port does not currently support architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()
set(VCPKG_POLICY_ALLOW_EMPTY_FOLDERS enabled)

# These featuresare ONLY RELEVANT FOR LINUX
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        cuda
        cxx11-abi
)
if("cuda" IN_LIST FEATURE_OPTIONS)
    set(USE_CUDA ON)
else()
    set(USE_CUDA OFF)
endif()

if("cxx11-abi" IN_LIST FEATURE_OPTIONS)
    set(USE_CXX11_ABI ON)
else()
    set(USE_CXX11_ABI OFF)
endif()

# Check if libc++.so.1 exists on system
if(VCPKG_TARGET_IS_LINUX)
    file(GLOB_RECURSE LIBCXX_LIB "/usr/lib/libc++.so.1" "/usr/local/lib/libc++.so.1")
    if(NOT LIBCXX_LIB)
        message(FATAL_ERROR "
        *******************************************************
        * libc++.so.1 not found.                              *
        * You can install it on Ubuntu via:                   *
        *                                                     *
        *     sudo apt install libc++-dev                     *
        *******************************************************
        ")
    else()
        message(STATUS "libc++.so.1 found at ${LIBCXX_LIB}")
    endif()
endif()

# archive download managment
set(VERSION "0.15.1")
set(BASE_URL "https://github.com/isl-org/Open3D/releases/download/v${VERSION}/")

if(VCPKG_TARGET_IS_WINDOWS)
    set(ARCHIVE_FILENAME_RELEASE "open3d-devel-windows-amd64-${VERSION}.zip")
    set(ARCHIVE_FILENAME_DEBUG "open3d-devel-windows-amd64-${VERSION}-dbg.zip")
    set(SHA512_RELEASE edbcaab47cc43b78b00373596f83be634df62a16e27ca464d13277dc6faa426821837585df226326408587a2558bf53cd2dfbf51698d02bb1f60b61f8b7cf854)
    set(SHA512_DEBUG 6ac22e20c5ef1285761b99eb8bf57ab20e074336c3a9d0010e79a1254f81b065c1bb2c9b1b4ee3f5ab37015469a2e61f4b036e1fb3d4d7147b88b0575858aee5)
elseif(VCPKG_TARGET_IS_LINUX)
    if(USE_CXX11_ABI)
        if(USE_CUDA)
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-cxx11-abi-cuda-${VERSION}.tar.xz")
            set(SHA512_RELEASE 0)
        else()
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-cxx11-abi-${VERSION}.tar.xz")
            set(SHA512_RELEASE 0)
        endif()
    else()
        if(USE_CUDA)
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-pre-cxx11-abi-cuda-${VERSION}.tar.xz")
            set(SHA512_RELEASE 0)
        else()
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-pre-cxx11-abi-${VERSION}.tar.xz")
            set(SHA512_RELEASE 0)
        endif()
    endif()
    set(ARCHIVE_FILENAME_DEBUG ${ARCHIVE_FILENAME_RELEASE}) # on linux, no debug-specific releases exist
    set(SHA512_DEBUG ${SHA512_RELEASE})
endif()

set(ARCHIVE_URL_RELEASE "${BASE_URL}/${ARCHIVE_FILENAME_RELEASE}")
vcpkg_download_distfile(
    RELEASE_ARCHIVE
    URLS ${ARCHIVE_URL_RELEASE}
    FILENAME ${ARCHIVE_FILENAME_RELEASE}
    SHA512 ${SHA512_RELEASE}
)

set(ARCHIVE_URL_DEBUG "${BASE_URL}/${ARCHIVE_FILENAME_DEBUG}")
vcpkg_download_distfile(
    DEBUG_ARCHIVE
    URLS ${ARCHIVE_URL_DEBUG}
    FILENAME ${ARCHIVE_FILENAME_DEBUG}
    SHA512 ${SHA512_DEBUG}
)

vcpkg_extract_source_archive(
    src_release
    ARCHIVE ${RELEASE_ARCHIVE}
)

vcpkg_extract_source_archive(
    src_debug
    ARCHIVE ${DEBUG_ARCHIVE}
)

### installs

# Release files
file(INSTALL "${src_release}/include" DESTINATION "${CURRENT_PACKAGES_DIR}")
file(INSTALL "${src_release}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}")
if(VCPKG_TARGET_IS_WINDOWS)
    file(INSTALL "${src_release}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}")
    file(INSTALL "${src_release}/CMake/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
else()
    file(INSTALL "${src_release}/lib/cmake/Open3D" DESTINATION "${CURRENT_PACKAGES_DIR}/share" RENAME "${PORT}")
endif()

# Debug files (SAME AS RELEASE ON LINUX because Open3D provides no debug build there) 
file(INSTALL "${src_debug}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
file(INSTALL "${src_debug}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
if(VCPKG_TARGET_IS_WINDOWS)
    file(INSTALL "${src_debug}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}")
    file(INSTALL "${src_debug}/CMake/" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}")
else()
    file(INSTALL "${src_debug}/lib/cmake/Open3D" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/share" RENAME "${PORT}")
endif()

# usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}")

# figure out cmake targets
vcpkg_fixup_cmake_targets()

# install license from repo
set(LICENSE_URL "https://raw.githubusercontent.com/isl-org/Open3D/refs/tags/v${VERSION}/LICENSE")
set(LICENSE_FILENAME "LICENSE")

vcpkg_download_distfile(
    LICENSE
    URLS ${LICENSE_URL}
    FILENAME ${LICENSE_FILENAME}
    SHA512 ee25ddbb2a4463b8af9f876bfb8ba072725fdf7685ea61eac6ca46a0164c75457ef00526348b717419f772ca7a066cbd704540d2a68531d92074bb743f056a0b
)

vcpkg_install_copyright(FILE_LIST ${LICENSE}
                        COMMENT "source: ${LICENSE_URL}")