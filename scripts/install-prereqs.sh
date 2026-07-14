#!/usr/bin/env bash
set -euo pipefail

dry_run="${DRY_RUN:-0}"

log() {
  printf '%s\n' "$*"
}

run_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'

  if [ "${dry_run}" != "1" ]; then
    "$@"
  fi
}

require_command() {
  local command_name="$1"
  local install_hint="$2"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    log "Error: ${command_name} is required. ${install_hint}"
    exit 1
  fi
}

detect_os() {
  local uname_value
  uname_value="$(uname -s)"

  case "${uname_value}" in
    Darwin)
      printf 'macos'
      ;;
    Linux)
      if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        local distro="${ID:-}"
        local distro_like="${ID_LIKE:-}"

        case " ${distro} ${distro_like} " in
          *" debian "*|*" ubuntu "*)
            printf 'debian'
            ;;
          *)
            log "Error: unsupported Linux distribution: ${PRETTY_NAME:-unknown}."
            log "Supported Linux distributions are Ubuntu and Debian."
            exit 1
            ;;
        esac
      else
        log "Error: cannot detect Linux distribution because /etc/os-release is missing."
        exit 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      printf 'windows-git-bash'
      ;;
    *)
      log "Error: unsupported OS: ${uname_value}."
      exit 1
      ;;
  esac
}

detect_arch() {
  local uname_machine
  uname_machine="$(uname -m)"

  case "${uname_machine}" in
    x86_64|amd64)
      printf 'amd64'
      ;;
    arm64|aarch64)
      printf 'arm64'
      ;;
    *)
      log "Error: unsupported CPU architecture: ${uname_machine}."
      exit 1
      ;;
  esac
}

sudo_prefix() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi

  if [ "${dry_run}" = "1" ]; then
    printf 'sudo'
    return 0
  fi

  require_command sudo "Install sudo or run this script as root."
  printf 'sudo'
}

github_latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | sed -n 's/.*"tag_name": "\(v[^"]*\)".*/\1/p' | awk 'NR == 1 { print }'
}

temp_dir() {
  local name="$1"

  if [ "${dry_run}" = "1" ]; then
    printf '%s-dry-run-placeholder' "${name}"
  else
    mktemp -d
  fi
}

install_helmfile_from_github() {
  local os_name="$1"
  local arch="$2"
  local destination_dir="$3"
  local executable_name="helmfile"
  local version
  local asset_version
  local asset_name
  local checksum_name
  local archive_url
  local checksum_url
  local tmpdir

  if [ "${os_name}" = "windows" ]; then
    executable_name="helmfile.exe"
  fi

  if [ "${dry_run}" = "1" ]; then
    version="${HELMFILE_VERSION:-vLATEST}"
  else
    version="${HELMFILE_VERSION:-$(github_latest_tag helmfile/helmfile)}"
  fi
  if [ -z "${version}" ]; then
    log "Error: could not resolve latest Helmfile release."
    exit 1
  fi

  asset_version="${version#v}"
  asset_name="helmfile_${asset_version}_${os_name}_${arch}.tar.gz"
  checksum_name="helmfile_${asset_version}_checksums.txt"
  archive_url="https://github.com/helmfile/helmfile/releases/download/${version}/${asset_name}"
  checksum_url="https://github.com/helmfile/helmfile/releases/download/${version}/${checksum_name}"
  tmpdir="$(temp_dir helmfile)"

  log "Installing Helmfile ${version} from ${archive_url}"
  run_cmd mkdir -p "${tmpdir}"
  run_cmd curl -fsSL -o "${tmpdir}/${asset_name}" "${archive_url}"
  run_cmd curl -fsSL -o "${tmpdir}/${checksum_name}" "${checksum_url}"
  run_cmd bash -c 'cd "$1" && grep " $2$" "$3" | sha256sum --check' _ "${tmpdir}" "${asset_name}" "${checksum_name}"
  run_cmd tar -xzf "${tmpdir}/${asset_name}" -C "${tmpdir}"
  run_cmd mkdir -p "${destination_dir}"

  if [ "${os_name}" = "windows" ]; then
    run_cmd cp "${tmpdir}/${executable_name}" "${destination_dir}/${executable_name}"
    run_cmd chmod +x "${destination_dir}/${executable_name}"
  else
    local sudo_cmd
    sudo_cmd="$(sudo_prefix)"
    if [ -n "${sudo_cmd}" ]; then
      run_cmd "${sudo_cmd}" install -m 0755 "${tmpdir}/${executable_name}" "${destination_dir}/${executable_name}"
    else
      run_cmd install -m 0755 "${tmpdir}/${executable_name}" "${destination_dir}/${executable_name}"
    fi
  fi

  if [ "${dry_run}" != "1" ]; then
    rm -rf "${tmpdir}"
  fi
}

install_kind_binary_linux() {
  local arch="$1"
  local sudo_cmd
  local tmpdir
  sudo_cmd="$(sudo_prefix)"
  tmpdir="$(temp_dir kind)"

  log "Installing kind from kind.sigs.k8s.io."
  run_cmd mkdir -p "${tmpdir}"
  run_cmd curl -fsSLo "${tmpdir}/kind" "https://kind.sigs.k8s.io/dl/latest/kind-linux-${arch}"
  run_cmd curl -fsSLo "${tmpdir}/kind.sha256" "https://kind.sigs.k8s.io/dl/latest/kind-linux-${arch}.sha256"
  run_cmd bash -c 'echo "$(cat "$2")  $1" | sha256sum --check' _ "${tmpdir}/kind" "${tmpdir}/kind.sha256"

  if [ -n "${sudo_cmd}" ]; then
    run_cmd "${sudo_cmd}" install -m 0755 "${tmpdir}/kind" /usr/local/bin/kind
  else
    run_cmd install -m 0755 "${tmpdir}/kind" /usr/local/bin/kind
  fi

  if [ "${dry_run}" != "1" ]; then
    rm -rf "${tmpdir}"
  fi
}

install_kubectl_binary_linux() {
  local arch="$1"
  local sudo_cmd
  local tmpdir
  local version
  sudo_cmd="$(sudo_prefix)"
  tmpdir="$(temp_dir kubectl)"
  if [ "${dry_run}" = "1" ]; then
    version="${KUBECTL_VERSION:-vLATEST}"
  else
    version="${KUBECTL_VERSION:-$(curl -fsSL https://dl.k8s.io/release/stable.txt)}"
  fi

  log "Installing kubectl ${version} from dl.k8s.io."
  run_cmd mkdir -p "${tmpdir}"
  run_cmd curl -fsSLo "${tmpdir}/kubectl" "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl"
  run_cmd curl -fsSLo "${tmpdir}/kubectl.sha256" "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl.sha256"
  run_cmd bash -c 'echo "$(cat "$2")  $1" | sha256sum --check' _ "${tmpdir}/kubectl" "${tmpdir}/kubectl.sha256"

  if [ -n "${sudo_cmd}" ]; then
    run_cmd "${sudo_cmd}" install -m 0755 "${tmpdir}/kubectl" /usr/local/bin/kubectl
  else
    run_cmd install -m 0755 "${tmpdir}/kubectl" /usr/local/bin/kubectl
  fi

  if [ "${dry_run}" != "1" ]; then
    rm -rf "${tmpdir}"
  fi
}

remove_legacy_helm_repository() {
  local sudo_cmd="$1"
  local source_file="/etc/apt/sources.list.d/helm-stable-debian.list"

  if [ -f "${source_file}" ] && grep -q "baltocdn\\.com" "${source_file}"; then
    log "Removing obsolete Helm Baltocdn repository."

    if [ -n "${sudo_cmd}" ]; then
      run_cmd "${sudo_cmd}" rm -f "${source_file}"
    else
      run_cmd rm -f "${source_file}"
    fi
  fi
}

verify_helm_apt_key() {
  local key_file="$1"
  local expected_fingerprint="$2"
  local actual_fingerprint

  if [ "${dry_run}" = "1" ]; then
    log "+ verify Helm APT key fingerprint ${expected_fingerprint}"
    return 0
  fi

  actual_fingerprint="$(
    gpg --show-keys --with-colons "${key_file}" |
      awk -F: '$1 == "fpr" { print $10; exit }'
  )"

  if [ "${actual_fingerprint}" != "${expected_fingerprint}" ]; then
    log "Error: unexpected Helm APT key fingerprint: ${actual_fingerprint:-missing}."
    log "Expected Helm APT key fingerprint: ${expected_fingerprint}."
    exit 1
  fi
}

install_helm_debian() {
  local sudo_cmd="$1"
  local expected_fingerprint="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"
  local tmpdir
  tmpdir="$(temp_dir helm-apt)"

  log "Installing Helm through the current Buildkite-hosted Helm APT repository."
  run_cmd mkdir -p "${tmpdir}"
  run_cmd curl -fsSL -o "${tmpdir}/helm-key.asc" "https://packages.buildkite.com/helm-linux/helm-debian/gpgkey"
  verify_helm_apt_key "${tmpdir}/helm-key.asc" "${expected_fingerprint}"
  run_cmd gpg --batch --yes --dearmor --output "${tmpdir}/helm.gpg" "${tmpdir}/helm-key.asc"
  run_cmd bash -c 'printf "%s\n" "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" > "$1"' _ "${tmpdir}/helm.list"

  if [ -n "${sudo_cmd}" ]; then
    run_cmd "${sudo_cmd}" install -m 0755 -d /usr/share/keyrings
    run_cmd "${sudo_cmd}" install -m 0644 "${tmpdir}/helm.gpg" /usr/share/keyrings/helm.gpg
    run_cmd "${sudo_cmd}" install -m 0644 "${tmpdir}/helm.list" /etc/apt/sources.list.d/helm-stable-debian.list
    run_cmd "${sudo_cmd}" apt-get update
    run_cmd "${sudo_cmd}" apt-get install -y helm
  else
    run_cmd install -m 0755 -d /usr/share/keyrings
    run_cmd install -m 0644 "${tmpdir}/helm.gpg" /usr/share/keyrings/helm.gpg
    run_cmd install -m 0644 "${tmpdir}/helm.list" /etc/apt/sources.list.d/helm-stable-debian.list
    run_cmd apt-get update
    run_cmd apt-get install -y helm
  fi

  if [ "${dry_run}" != "1" ]; then
    rm -rf "${tmpdir}"
  fi
}

install_macos_prereqs() {
  require_command brew "Install Homebrew from https://brew.sh, then rerun make install-prereqs."

  log "Detected macOS. Using Homebrew."

  if ! command -v docker >/dev/null 2>&1; then
    run_cmd brew install --cask docker
  fi

  local formulae=()
  command -v kind >/dev/null 2>&1 || formulae+=(kind)
  command -v kubectl >/dev/null 2>&1 || formulae+=(kubectl)
  command -v helm >/dev/null 2>&1 || formulae+=(helm)
  command -v helmfile >/dev/null 2>&1 || formulae+=(helmfile)

  if [ "${#formulae[@]}" -gt 0 ]; then
    run_cmd brew install "${formulae[@]}"
  else
    log "Homebrew-managed tools are already available."
  fi

  log "If Docker Desktop was installed or updated, open Docker Desktop before running make kind-up."
}

install_debian_prereqs() {
  local arch
  local sudo_cmd
  arch="$(detect_arch)"
  sudo_cmd="$(sudo_prefix)"

  log "Detected Ubuntu/Debian. Using apt-get plus official tool downloads where apt packages are not reliable."
  remove_legacy_helm_repository "${sudo_cmd}"

  if [ -n "${sudo_cmd}" ]; then
    run_cmd "${sudo_cmd}" apt-get update
    run_cmd "${sudo_cmd}" apt-get install -y apt-transport-https ca-certificates coreutils curl gnupg gzip make tar
    command -v docker >/dev/null 2>&1 || run_cmd "${sudo_cmd}" apt-get install -y docker.io
  else
    run_cmd apt-get update
    run_cmd apt-get install -y apt-transport-https ca-certificates coreutils curl gnupg gzip make tar
    command -v docker >/dev/null 2>&1 || run_cmd apt-get install -y docker.io
  fi

  if ! command -v helm >/dev/null 2>&1; then
    install_helm_debian "${sudo_cmd}"
  fi

  command -v kubectl >/dev/null 2>&1 || install_kubectl_binary_linux "${arch}"
  command -v kind >/dev/null 2>&1 || install_kind_binary_linux "${arch}"
  command -v helmfile >/dev/null 2>&1 || install_helmfile_from_github linux "${arch}" /usr/local/bin

  log "If Docker was installed for the first time, add your user to the docker group or use sudo for Docker."
  log "You may need to log out and back in before Docker group membership takes effect."
}

install_windows_git_bash_prereqs() {
  local arch
  arch="$(detect_arch)"

  require_command winget "Install Windows Package Manager or install the tools manually."

  log "Detected Windows from Git Bash. Using winget where packages exist."

  command -v docker >/dev/null 2>&1 || run_cmd winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
  command -v kubectl >/dev/null 2>&1 || run_cmd winget install -e --id Kubernetes.kubectl --accept-source-agreements --accept-package-agreements
  command -v kind >/dev/null 2>&1 || run_cmd winget install -e --id Kubernetes.kind --accept-source-agreements --accept-package-agreements
  command -v helm >/dev/null 2>&1 || run_cmd winget install -e --id Helm.Helm --accept-source-agreements --accept-package-agreements

  if ! command -v helmfile >/dev/null 2>&1; then
    if command -v scoop >/dev/null 2>&1; then
      run_cmd scoop install helmfile
    else
      install_helmfile_from_github windows "${arch}" "${HOME}/bin"
      log "Helmfile was installed to ${HOME}/bin. Add that directory to PATH if helmfile is not found."
    fi
  fi

  log "Docker Desktop may require admin approval, a restart, or manual startup before kind can use it."
}

main() {
  local os_name
  os_name="$(detect_os)"

  if [ "${dry_run}" = "1" ]; then
    log "DRY_RUN=1 is set. Commands will be printed but not executed."
  fi

  case "${os_name}" in
    macos)
      install_macos_prereqs
      ;;
    debian)
      install_debian_prereqs
      ;;
    windows-git-bash)
      install_windows_git_bash_prereqs
      ;;
    *)
      log "Error: unsupported OS detection result: ${os_name}."
      exit 1
      ;;
  esac

  log "Prerequisite installation step completed."
  log "Run make check-prereqs to verify the required tools are available."
}

main "$@"
