# vcpkg checks and configs
if(NOT (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "amd64"))
    message(FATAL_ERROR "This port does not currently support architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()
set(VCPKG_POLICY_ALLOW_EMPTY_FOLDERS enabled)

# These features are ONLY RELEVANT FOR LINUX
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        cuda      USE_CUDA
        cxx11-abi USE_CXX11_ABI # ON by default
)

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
set(BASE_URL "https://github.com/isl-org/Open3D/releases/download/v${VERSION}")

if(VCPKG_TARGET_IS_WINDOWS)
    set(ARCHIVE_FILENAME_RELEASE "open3d-devel-windows-amd64-${VERSION}.zip")
    set(ARCHIVE_FILENAME_DEBUG "open3d-devel-windows-amd64-${VERSION}-dbg.zip")
    set(SHA512_RELEASE edbcaab47cc43b78b00373596f83be634df62a16e27ca464d13277dc6faa426821837585df226326408587a2558bf53cd2dfbf51698d02bb1f60b61f8b7cf854)
    set(SHA512_DEBUG 6ac22e20c5ef1285761b99eb8bf57ab20e074336c3a9d0010e79a1254f81b065c1bb2c9b1b4ee3f5ab37015469a2e61f4b036e1fb3d4d7147b88b0575858aee5)
elseif(VCPKG_TARGET_IS_LINUX)
    if(USE_CXX11_ABI)
        if(USE_CUDA)
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-cxx11-abi-cuda-${VERSION}.tar.xz")
            set(SHA512_RELEASE e8cd7c4f5c4442e7f267954810969dc7204c37ee43fd3e8b591c248ef56eb0986297f48391b5dad8faf4111ccc3c1ffc87bcde0f9a2cd46c3e0db9b728be4168)
        else()
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-cxx11-abi-${VERSION}.tar.xz")
            set(SHA512_RELEASE 1e0e4cc08fe4bf17a6edcb83added89b450df72fddc4e573eb2ba06e910efad341bc16de6b7274d93ce63dcaef5d25064fd4fe55141a727f0b862365026e6b68)
        endif()
    else()
        if(USE_CUDA)
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-pre-cxx11-abi-cuda-${VERSION}.tar.xz")
            set(SHA512_RELEASE 3bcfb0316517c6c9b9e5f1d89700be9135c2dcf97974a41402427d23d93ef9901a381a55129399aecdc00babd0fa16002c50b306d3199f2af8212b311fdf6ff6)
        else()
            set(ARCHIVE_FILENAME_RELEASE "open3d-devel-linux-x86_64-pre-cxx11-abi-${VERSION}.tar.xz")
            set(SHA512_RELEASE da792590cff40cc0cc32b1ea43bcde67a174bb10080ebc5a38841a811e915be8a350a63d044475e30b2b4bcdc4a9ec66e2bfa6e15e523059a61d3617be6cad84)
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
    if(USE_CUDA)
        file(INSTALL "${src_release}/share/resources" DESTINATION "${CURRENT_PACKAGES_DIR}")
    endif()
endif()

# Debug files (SAME AS RELEASE ON LINUX because Open3D provides no debug build there) 
file(INSTALL "${src_debug}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
if(VCPKG_TARGET_IS_WINDOWS)
    file(INSTALL "${src_debug}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
    file(INSTALL "${src_debug}/CMake/" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}")
endif()

# usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# figure out cmake targets
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_fixup_cmake_targets() # *.cmake already in right dir
else()
    vcpkg_fixup_cmake_targets(CONFIG_PATH "/lib/cmake/Open3D") # *.cmake need to be moved
    if(NOT VCPKG_BUILD_TYPE STREQUAL "debug")
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share") # vcpkg_fixup_cmake_targets will not handle *-debug.cmake
    endif()                                                        # files in this case, so manual cleanup necessary
endif()


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