#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 INPUT_DIR OUTPUT_DIR [MAPQ=30] [THREADS=2]" >&2
    exit 2
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAPQ="${3:-30}"
THREADS="${4:-2}"
SAMTOOLS="${SAMTOOLS:-samtools}"
EXCLUDE_FLAGS=2308  # unmapped (4) + secondary (256) + supplementary (2048)

if [ ! -d "${INPUT_DIR}" ]; then
    echo "Input directory does not exist: ${INPUT_DIR}" >&2
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"
shopt -s nullglob
bams=("${INPUT_DIR}"/*.bam)
if [ "${#bams[@]}" -eq 0 ]; then
    echo "No BAM files found in ${INPUT_DIR}" >&2
    exit 1
fi

echo "samtools=${SAMTOOLS}"
echo "input_dir=${INPUT_DIR}"
echo "output_dir=${OUTPUT_DIR}"
echo "mapq=${MAPQ}"
echo "exclude_flags=${EXCLUDE_FLAGS}"
echo "threads=${THREADS}"

for bam in "${bams[@]}"; do
    sample="$(basename "${bam}" .bam)"
    out="${OUTPUT_DIR}/${sample}.unique.bam"
    tmp="${out}.tmp.${PBS_JOBID:-$$}.bam"

    if [ -s "${out}" ] && [ -s "${out}.bai" ]; then
        echo "[skip] ${sample}"
        continue
    fi

    echo "[filter] ${sample} $(date)"
    "${SAMTOOLS}" view \
        -@ "${THREADS}" \
        -b \
        -q "${MAPQ}" \
        -F "${EXCLUDE_FLAGS}" \
        --save-counts "${OUTPUT_DIR}/${sample}.unique.filter_counts.json" \
        -o "${tmp}" \
        "${bam}"
    "${SAMTOOLS}" index -@ "${THREADS}" "${tmp}"
    mv "${tmp}" "${out}"
    mv "${tmp}.bai" "${out}.bai"
    "${SAMTOOLS}" flagstat -@ "${THREADS}" "${out}" > "${OUTPUT_DIR}/${sample}.unique.flagstat.txt"
done

echo "completed $(date)"
