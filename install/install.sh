#!/usr/bin/env bash
set -euo pipefail

# ai-toolkit installer
# Installs a suite's skills into:
#   - user:    ~/.claude/skills
#   - project: <repo>/.claude/skills
#
# Default method: symlink (recommended)
# Optional method: copy
#
# Usage:
#   ./install/install.sh intentforge --target user
#   ./install/install.sh intentforge --target project --project-root /path/to/repo
#   ./install/install.sh intentforge --target user --method copy
#
# Notes:
# - This script installs ONLY skill directories (each containing SKILL.md).
# - Runtime artifacts (.intent-forge/) belong in target repos and should not be installed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SUITE_NAME="${1:-}"
if [[ -z "${SUITE_NAME}" ]]; then
  echo "ERROR: missing suite name."
  echo "Usage: $0 <suite-name> --target user|project [--method symlink|copy] [--project-root <path>]"
  exit 1
fi
shift || true

TARGET="user"
METHOD="symlink"
PROJECT_ROOT=""
VERBOSE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"; shift 2;;
    --method)
      METHOD="${2:-}"; shift 2;;
    --project-root)
      PROJECT_ROOT="${2:-}"; shift 2;;
    --verbose)
      VERBOSE="true"; shift 1;;
    -h|--help)
      echo "Usage: $0 <suite-name> --target user|project [--method symlink|copy] [--project-root <path>] [--verbose]"
      exit 0;;
    *)
      echo "ERROR: unknown arg: $1"; exit 1;;
  esac
done

SUITE_DIR="${ROOT_DIR}/suites/${SUITE_NAME}"
SKILLS_DIR="${SUITE_DIR}/skills"
SUITE_YAML="${SUITE_DIR}/suite.yaml"

if [[ ! -d "${SKILLS_DIR}" ]]; then
  echo "ERROR: suite not found or missing skills dir: ${SKILLS_DIR}"
  exit 1
fi

if [[ "${TARGET}" != "user" && "${TARGET}" != "project" ]]; then
  echo "ERROR: --target must be 'user' or 'project'"
  exit 1
fi

if [[ "${METHOD}" != "symlink" && "${METHOD}" != "copy" ]]; then
  echo "ERROR: --method must be 'symlink' or 'copy'"
  exit 1
fi

if [[ "${TARGET}" == "project" ]]; then
  if [[ -z "${PROJECT_ROOT}" ]]; then
    PROJECT_ROOT="$(pwd)"
  fi
  DEST_SKILLS="${PROJECT_ROOT}/.claude/skills"
else
  DEST_SKILLS="${HOME}/.claude/skills"
fi

mkdir -p "${DEST_SKILLS}"

log() {
  if [[ "${VERBOSE}" == "true" ]]; then
    echo "$@"
  fi
}

# Extract skill list:
# Prefer suite.yaml if present. Fallback: list directories under skills/ containing SKILL.md
get_skills() {
  local skills=()
  if [[ -f "${SUITE_YAML}" ]]; then
    # Very small YAML parser for the known structure:
    # skills:
    #   - name
    while IFS= read -r line; do
      line="${line#"${line%%[![:space:]]*}"}"   # trim leading
      if [[ "${line}" =~ ^-\ ([a-zA-Z0-9._-]+)$ ]]; then
        skills+=("${BASH_REMATCH[1]}")
      fi
    done < <(grep -E '^\s*-\s*[a-zA-Z0-9._-]+' "${SUITE_YAML}" || true)
  fi

  if [[ ${#skills[@]} -eq 0 ]]; then
    while IFS= read -r d; do
      if [[ -f "${d}/SKILL.md" ]]; then
        skills+=("$(basename "${d}")")
      fi
    done < <(find "${SKILLS_DIR}" -mindepth 1 -maxdepth 1 -type d | sort)
  fi

  printf '%s\n' "${skills[@]}"
}

install_one() {
  local skill_name="$1"
  local src="${SKILLS_DIR}/${skill_name}"
  local dest="${DEST_SKILLS}/${skill_name}"

  if [[ ! -d "${src}" ]]; then
    echo "WARN: skill listed but not found: ${skill_name} (${src})"
    return 0
  fi
  if [[ ! -f "${src}/SKILL.md" ]]; then
    echo "WARN: missing SKILL.md for ${skill_name}, skipping."
    return 0
  fi

  # remove existing
  if [[ -e "${dest}" || -L "${dest}" ]]; then
    rm -rf "${dest}"
  fi

  if [[ "${METHOD}" == "symlink" ]]; then
    ln -s "${src}" "${dest}"
    log "linked: ${dest} -> ${src}"
  else
    cp -R "${src}" "${dest}"
    log "copied: ${src} -> ${dest}"
  fi
}

echo "Installing suite '${SUITE_NAME}' to: ${DEST_SKILLS}"
echo "Method: ${METHOD}"
echo "Suite dir: ${SUITE_DIR}"

mapfile -t SKILLS < <(get_skills)

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "ERROR: no skills found under ${SKILLS_DIR}"
  exit 1
fi

for s in "${SKILLS[@]}"; do
  install_one "${s}"
done

echo ""
echo "Installed skills:"
for s in "${SKILLS[@]}"; do
  echo "  - ${s}"
done

echo ""
if [[ "${TARGET}" == "project" ]]; then
  echo "Next: run Claude Code from this repo so it discovers .claude/skills."
else
  echo "Next: run Claude Code anywhere; these skills are now available globally for your user."
fi