#!/usr/bin/env bash
set -euo pipefail

REPO_BASE="https://diviyampathak.github.io/xanmodtools"
KEY_URL="${REPO_BASE}/xanmodtools.gpg"
KEYRING="/etc/apt/keyrings/xanmodtools.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/xanmodtools.list"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash install.sh"
  exit 1
fi

. /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "Unsupported distribution: ${ID:-unknown}. This installer currently supports Ubuntu only."
  exit 1
fi

if [[ "${VERSION_CODENAME:-}" != "noble" ]]; then
  echo "Unsupported Ubuntu release: ${VERSION_CODENAME:-unknown}. This repository currently publishes noble packages."
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [[ "${ARCH}" != "amd64" ]]; then
  echo "Unsupported architecture: ${ARCH}. This repository currently publishes amd64 packages."
  exit 1
fi

mkdir -p /etc/apt/keyrings

TMP_KEY="$(mktemp)"
trap 'rm -f "${TMP_KEY}"' EXIT

curl -fsSL "${KEY_URL}" -o "${TMP_KEY}"
gpg --dearmor < "${TMP_KEY}" > "${KEYRING}"
chmod 0644 "${KEYRING}"

echo "deb [arch=amd64 signed-by=${KEYRING}] ${REPO_BASE} noble main" > "${SOURCES_LIST}"

apt-get update

KERNEL="$(uname -r)"
PACKAGE="linux-tools-${KERNEL}"

echo "Detected kernel: ${KERNEL}"
echo "Requested package: ${PACKAGE}"

if apt-cache show "${PACKAGE}" >/dev/null 2>&1; then
  apt-get install -y "${PACKAGE}"
else
  echo "No matching package is currently published for ${KERNEL}."
  echo "The repository was configured successfully, but the kernel-specific package is not available yet."
  echo "Available XanMod packages:"
  apt-cache search '^linux-tools-.*xanmod' || true
  exit 2
fi

echo "XanMod tools repository configured successfully."
