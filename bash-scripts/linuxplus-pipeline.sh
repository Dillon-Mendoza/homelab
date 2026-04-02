#!/usr/bin/env bash
set -euo pipefail

# Linux+ PDF pipeline for homelab study workflow
# Converts PDFs into cleaner, chunked text for Gemini CLI usage.

SCRIPT_NAME="$(basename "$0")"
BASE_DIR="${HOME}/homelab"
WORK_DIR="${BASE_DIR}/linuxplus"
RAW_DIR="${WORK_DIR}/raw"
TEXT_DIR="${WORK_DIR}/text"
CHUNK_DIR="${WORK_DIR}/chunks"
PROMPT_DIR="${WORK_DIR}/prompts"
OUTPUT_DIR="${WORK_DIR}/outputs"
LOG_DIR="${BASE_DIR}/logs"

CHUNK_LINES=120

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} /path/to/file.pdf
  ${SCRIPT_NAME} /path/to/folder/of/pdfs

What it does:
  - Copies PDFs into ${RAW_DIR}
  - Converts PDFs to text
  - Cleans extracted text
  - Splits text into token-friendlier chunks
  - Creates Gemini prompt files for each chunk

Requirements:
  - pdftotext (poppler-utils)

Examples:
  ${SCRIPT_NAME} ~/Downloads/week-2.pdf
  ${SCRIPT_NAME} ~/Downloads/linuxplus-pdfs
EOF
}

log() {
  local msg="$1"
  mkdir -p "${LOG_DIR}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" | tee -a "${LOG_DIR}/linuxplus-pipeline.log"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}"
    echo "Install it with:"
    echo "  sudo dnf install poppler-utils"
    exit 1
  fi
}

setup_dirs() {
  mkdir -p \
    "${RAW_DIR}" \
    "${TEXT_DIR}" \
    "${CHUNK_DIR}" \
    "${PROMPT_DIR}" \
    "${OUTPUT_DIR}" \
    "${LOG_DIR}"
}

clean_text() {
  local input_file="$1"
  local output_file="$2"

  # Clean common PDF extraction junk while preserving useful commands.
  sed -E '
    s/\r//g;
    s/[[:space:]]+$//g;
    s/^[[:space:]]+//g;
    s/[[:space:]][[:space:]]+/ /g;
  ' "${input_file}" \
    | awk '
        NF > 0 { print }
      ' \
    | grep -vE '^[0-9]+/[0-9]+$|^Page [0-9]+$|^• https?://[^ ]+$' \
    > "${output_file}"
}

make_prompts() {
  local pdf_base="$1"
  local chunk_file="$2"
  local prompt_file="$3"

  cat > "${prompt_file}" <<EOF
Read the attached chunk below and follow GEMINI.md in the current directory.

This content came from the Linux+ study PDF: ${pdf_base}

Your job:
1. Explain the section in plain language
2. Identify the most important Linux commands
3. Turn the section into a hands-on Fedora lab
4. Suggest one Bash automation idea based on the topic
5. Call out security risks or best practices
6. Give me 3 Linux+ style review questions
7. Format the response into:
   - Summary
   - Commands
   - Lab
   - Automation Idea
   - Security Notes
   - Review Questions

Chunk content:
----------------------------------------------------------------
EOF

  cat "${chunk_file}" >> "${prompt_file}"

  cat >> "${prompt_file}" <<'EOF'

----------------------------------------------------------------
EOF
}

process_pdf() {
  local pdf_path="$1"
  local pdf_name pdf_base raw_pdf raw_text clean_txt pdf_chunk_dir pdf_prompt_dir

  pdf_name="$(basename "${pdf_path}")"
  pdf_base="${pdf_name%.pdf}"

  raw_pdf="${RAW_DIR}/${pdf_name}"
  raw_text="${TEXT_DIR}/${pdf_base}.raw.txt"
  clean_txt="${TEXT_DIR}/${pdf_base}.clean.txt"
  pdf_chunk_dir="${CHUNK_DIR}/${pdf_base}"
  pdf_prompt_dir="${PROMPT_DIR}/${pdf_base}"

  log "Processing PDF: ${pdf_name}"

  cp -f "${pdf_path}" "${raw_pdf}"

  pdftotext "${raw_pdf}" "${raw_text}"
  clean_text "${raw_text}" "${clean_txt}"

  mkdir -p "${pdf_chunk_dir}" "${pdf_prompt_dir}"

  split -d -l "${CHUNK_LINES}" --additional-suffix=.txt "${clean_txt}" "${pdf_chunk_dir}/chunk_"

  for chunk_file in "${pdf_chunk_dir}"/chunk_*.txt; do
    local chunk_name prompt_file
    chunk_name="$(basename "${chunk_file}" .txt)"
    prompt_file="${pdf_prompt_dir}/${chunk_name}.prompt.txt"
    make_prompts "${pdf_base}" "${chunk_file}" "${prompt_file}"
  done

  log "Finished: ${pdf_name}"
  echo
  echo "Created:"
  echo "  Clean text: ${clean_txt}"
  echo "  Chunks:     ${pdf_chunk_dir}"
  echo "  Prompts:    ${pdf_prompt_dir}"
  echo
}

main() {
  local target="${1:-}"

  if [[ -z "${target}" ]]; then
    usage
    exit 1
  fi

  require_cmd pdftotext
  setup_dirs

  if [[ -f "${target}" && "${target}" == *.pdf ]]; then
    process_pdf "${target}"
  elif [[ -d "${target}" ]]; then
    shopt -s nullglob
    local pdfs=( "${target}"/*.pdf )
    shopt -u nullglob

    if [[ ${#pdfs[@]} -eq 0 ]]; then
      echo "No PDFs found in: ${target}"
      exit 1
    fi

    for pdf in "${pdfs[@]}"; do
      process_pdf "${pdf}"
    done
  else
    echo "Invalid target: ${target}"
    usage
    exit 1
  fi

  cat <<EOF

Next step:
  Start Gemini from:
    cd ${BASE_DIR}

  Then use one of the generated prompt files:
    cat linuxplus/prompts/<pdf-name>/chunk_00.prompt.txt | gemini

Example:
    cat linuxplus/prompts/week-2/chunk_00.prompt.txt | gemini
EOF
}

main "$@"