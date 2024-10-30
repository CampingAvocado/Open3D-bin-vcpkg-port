# vcpkg checks and configs
if(NOT (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "amd64"))
    message(FATAL_ERROR "This port does not currently support architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()
set(VCPKG_POLICY_ALLOW_EMPTY_FOLDERS enabled)

# custom bools ONLY RELEVANT FOR LINUX
set(VCPKG_USE_CUDA OFF CACHE BOOL "Use CUDA")
set(VCPKG_CXX11_ABI ON CACHE BOOL "Relevant if you need old ABI, e.g. to work with PyTorch / TensorFlow libraries.")

# archive download managment
set(VERSION "0.15.1")
set(BASE_URL "https://github.com/isl-org/Open3D/releases/download/v${VERSION}/")

if(VCPKG_TARGET_IS_WINDOWS)
    set(ARCHIVE_FILENAME "open3d-devel-windows-amd64-${VERSION}.zip")
    set(ARCHIVE_FILENAME_DEBUG "open3d-devel-windows-amd64-${VERSION}-dbg.zip")
elseif(VCPKG_TARGET_IS_LINUX)
    if(VCPKG_CXX11_ABI)
        if(VCPKG_USE_CUDA)
            set(ARCHIVE_FILENAME "open3d-devel-linux-x86_64-cxx11-abi-cuda-${VERSION}.tar.xz")
        else()
            set(ARCHIVE_FILENAME "open3d-devel-linux-x86_64-cxx11-abi-${VERSION}.tar.xz")
        endif()
    else()
        if(VCPKG_USE_CUDA)
            set(ARCHIVE_FILENAME "open3d-devel-linux-x86_64-pre-cxx11-abi-cuda-${VERSION}.tar.xz")
        else()
            set(ARCHIVE_FILENAME "open3d-devel-linux-x86_64-pre-cxx11-abi-${VERSION}.tar.xz")
        endif()
    endif()
    set(ARCHIVE_FILENAME_DEBUG ${ARCHIVE_FILENAME}) # on linux, no debug-specific releases exist
endif()

set(ARCHIVE_URL "${BASE_URL}/${ARCHIVE_FILENAME}")
vcpkg_download_distfile(
    RELEASE_ARCHIVE
    URLS ${ARCHIVE_URL}
    FILENAME ${ARCHIVE_FILENAME}
    SHA512 edbcaab47cc43b78b00373596f83be634df62a16e27ca464d13277dc6faa426821837585df226326408587a2558bf53cd2dfbf51698d02bb1f60b61f8b7cf854
)

set(ARCHIVE_URL_DEBUG "${BASE_URL}/${ARCHIVE_FILENAME_DEBUG}")
vcpkg_download_distfile(
    DEBUG_ARCHIVE
    URLS ${ARCHIVE_URL_DEBUG}
    FILENAME ${ARCHIVE_FILENAME_DEBUG}
    SHA512 6ac22e20c5ef1285761b99eb8bf57ab20e074336c3a9d0010e79a1254f81b065c1bb2c9b1b4ee3f5ab37015469a2e61f4b036e1fb3d4d7147b88b0575858aee5
)

vcpkg_extract_source_archive(
    src
    ARCHIVE ${RELEASE_ARCHIVE}
)

vcpkg_extract_source_archive(
    src_debug
    ARCHIVE ${DEBUG_ARCHIVE}
)

### installs

# Release files
file(INSTALL "${src}/include" DESTINATION "${CURRENT_PACKAGES_DIR}")
file(INSTALL "${src}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}")
file(INSTALL "${src}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}")
file(INSTALL "${src}/CMake/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Debug files (SAME AS RELEASE ON LINUX because Open3D provides no debug build there) 
file(INSTALL "${src_debug}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
file(INSTALL "${src_debug}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
file(INSTALL "${src_debug}/CMake" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}")

# usage file
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# figure out cmake targets
vcpkg_fixup_cmake_targets(CONFIG_PATH "share/${PORT}")

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