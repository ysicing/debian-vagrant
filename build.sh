#!/bin/bash

set -e

. scripts/utils.sh

# function usage {
#   echo "usage: $0 [stable|{x.y.z}]"
#   echo "       where {x.y.z} is a valid Debian version (e.g. 11.0.0)"
#   exit
# }

# function get_version {
#     PAGE=$(curl -s https://www.debian.org/CD/netinst/)
#     if [[ $PAGE =~ \<a\ href=\"https:\/\/cdimage\.debian\.org\/debian-cd\/current\/amd64\/bt-cd\/debian-([0-10\.]+)-amd64-netinst\.iso ]]; then
#         echo "${BASH_REMATCH[1]}"
#     else
#         abort "Failed to get current stable version number. Aborting."
#     fi
# }

ARCH="amd64"
VERSION="11.0.0"
# RELEASE_SPECIFIER="$1"
# case "$RELEASE_SPECIFIER" in
#     "" | "stable")
#         VERSION="current"
#         VERSION_NUMBER=$(get_version)
#         MIRROR_DIR="release/${VERSION_NUMBER}"
#     ;;
#     *.*.*)
#         VERSION="${RELEASE_SPECIFIER}"
#         MIRROR_DIR="archive/${VERSION}"
#     ;;
#     *)
#         usage
#     ;;
# esac

# https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.4.0-amd64-netinst.iso
# https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current/amd64/iso-cd/debian-10.4.0-amd64-netinst.iso

VERSION_NUMBER="${VERSION_NUMBER:-$VERSION}"

FOLDER_BASE=$(pwd)
FOLDER_ISO="${FOLDER_BASE}/iso"
DEBIAN_MIRROR="cdimage.debian.org"
DEBIAN_URL="https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current/amd64/iso-cd"
DEBIAN_ISO_NAME="debian-${VERSION_NUMBER}-${ARCH}-netinst.iso"
DEBIAN_ISO_URL="${DEBIAN_URL}/${DEBIAN_ISO_NAME}"
DEBIAN_ISO_FILE="${FOLDER_ISO}/${DEBIAN_ISO_NAME}"

VBGA_DEBIAN_PATH="/usr/share/virtualbox/VBoxGuestAdditions.iso"
VBGA_ARCH_PATH="/usr/lib/virtualbox/additions/VBoxGuestAdditions.iso"
VBGA_DARWIN_PATH="/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"
PACKER_JSON="${FOLDER_BASE}/debian11.json"
BOX="debian-11-amd64"

function dep_vagrant {
    if [[ -z $(which vagrant) ]]; then
        abort "Could not find Vagrant. Aborting."
    fi
}

function dep_virtualbox {
    if [[ -z $(which VBoxManage) ]]; then
        abort "Could not find VirtualBox and VBoxManage. Aborting."
    fi

    if [[ ! -f $VBGA_DEBIAN_PATH && ! -f $VBGA_ARCH_PATH && ! -f $VBGA_DARWIN_PATH ]]; then
        abort "Could not find VirtualBox Guest Additions. Aborting."
    fi
}

function dep_7z {
    if [[ -z $(which 7z) ]]; then
        abort "Could not find 7z. Aborting."
    fi
}

function dep_mkisofs {
    if [[ -z $(which mkisofs || which genisoimage) ]]; then
        abort "Could not find mkisofs. Aborting."
    fi
}

function dep_packer {
    if [[ -z $(which packer) ]];then
        abort "Could not find packer. Aborting."
    fi
}

function download_iso {
    if [ ! -f "${DEBIAN_ISO_FILE}" ]; then
        info "Downloading ${DEBIAN_ISO_NAME} from ${DEBIAN_ISO_URL} ..."
        if ! curl --progress-bar --output "${DEBIAN_ISO_FILE}" \
                --location "${DEBIAN_ISO_URL}" --fail
        then
            abort "Download failed. Maybe the requested version doesn't exist?"
        fi
    fi
}

function check_isosum {
    if [ -f "${DEBIAN_ISO_FILE}" ]; then
        iso_checksum=$(sha256sum ${DEBIAN_ISO_FILE} | awk '{print $1}')
        info "${DEBIAN_ISO_NAME} sha256sum: ${iso_checksum}"
        cp -a ${PACKER_JSON}.example ${PACKER_JSON}
        sed -i "" 's#xxxx_xxxx#'${iso_checksum}'#g' ${PACKER_JSON}
        sed -i "" 's#debian.iso#'${DEBIAN_ISO_NAME}'#g' ${PACKER_JSON}
    fi
}

function vbox_unregister {
    if VBoxManage showvminfo "${BOX}" >/dev/null 2>/dev/null; then
        read -p "${txtred}Are you sure you want to destroy ${BOX}? ${txtrst}"
        if [ "$REPLY" == "y" ]; then
            VBoxManage unregistervm "${BOX}" --delete > /dev/null
            if [ $? -ne 0 ]; then
                abort "Failed to destroy ${BOX}. Aborting."
            fi
        else
            abort "VM ${BOX} already exist. Aborting."
        fi
    fi
}

dep_vagrant
dep_virtualbox
dep_7z
dep_mkisofs

download_iso
check_isosum

vbox_unregister

dep_packer

info "start build k8s debian box by packer ..."

packer build  ${PACKER_JSON}
