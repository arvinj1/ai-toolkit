#!/usr/bin/env bash
set -euo pipefail

# ai-toolkit uninstaller
# Removes a suite's installed skill links/copies from:
#   - user:    ~/.claude/skills
#   - project: <repo>/.claude/skills
#
# Usage:
#   ./install/uninstall.sh intentforge --target user
#   ./install/uninstall.sh intentforge --target project --project-root /path/to/repo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SUITE_NAME="${1:-}"
if [[ -z "${SUITE_NAME}" ]]; then
  echo "ERROR: missing suite name."
  echo "Usage: $0 <suite-name> --target user|project [--project-root <path>]"
  exit 1
fi
shift || true

TARGET="user"
PROJECT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"; shift 2;;
    --project-root)
      PROJECT_ROOT="${2:-}"; shift 2;;
    -h|--help)
      echo "Usage: $0 <suite-name> --target user|project [--project-root <path>]"
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

if [[ "${TARGET}" == "project" ]]; then
  if [[ -z "${PROJECT_ROOT}" ]]; then
    PROJECT_ROOT="$(pwd)"
  fi
  DEST_SKILLS="${PROJECT_ROOT}/.claude/skills"
else
  DEST_SKILLS="${HOME}/.claude/skills"
fi

if [[ ! -d "${DEST_SKILLS}" ]]; then
  echo "Nothing to uninstall; destination not found: ${DEST_SKILLS}"
  exit 0
fi

get_skills() {
  local skills=()
  if [[ -f "${SUITE_YAML}" ]]; then
    while IFS= read -r line; do
      line="${line#"${line%%[![:space:]]*}"}"
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

mapfile -t SKILLS < <(get_skills)

echo "Uninstalling suite '${SUITE_NAME}' from: ${DEST_SKILLS}"

for s in "${SKILLS[@]}"; do
  dest="${DEST_SKILLS}/${s}"
  if [[ -e "${dest}" || -L "${dest}" ]]; then
    rm -rf "${dest}"
    echo "  removed: ${s}"
  else
    echo "  not found: ${s}"
  fi
done

echo "Done."