#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 INPUT_BAM_OR_DIR OUTPUT_DIR [MAPQ=30] [THREADS=2]" >&2
    exit 2
fi

INPUT="$1"
OUTPUT_DIR="$2"
MAPQ="${3:-30}"
THREADS="${4:-2}"
SAMTOOLS="${SAMTOOLS:-samtools}"
EXCLUDE_FLAGS=2308  # unmapped (4) + secondary (256) + supplementary (2048)
FILTER_EXPRESSION='!exists([XS])'

if [ -d "${INPUT}" ]; then
    shopt -s nullglob
    bams=("${INPUT}"/*.bam)
elif [ -f "${INPUT}" ]; then
    bams=("${INPUT}")
else
    echo "Input BAM or directory does not exist: ${INPUT}" >&2
    exit 1
fi

if [ "${#bams[@]}" -eq 0 ]; then
    echo "No BAM files found: ${INPUT}" >&2
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"
echo "samtools=${SAMTOOLS}"
echo "input=${INPUT}"
echo "output_dir=${OUTPUT_DIR}"
echo "mapq=${MAPQ}"
echo "exclude_flags=${EXCLUDE_FLAGS}"
echo "filter_expression=${FILTER_EXPRESSION}"
echo "threads=${THREADS}"

for bam in "${bams[@]}"; do
    sample="$(basename "${bam}" .bam)"
    prefix="${sample}.mapq${MAPQ}.noXS"
    out="${OUTPUT_DIR}/${prefix}.bam"
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
        -e "${FILTER_EXPRESSION}" \
        --save-counts "${OUTPUT_DIR}/${prefix}.filter_counts.json" \
        -o "${tmp}" \
        "${bam}"
    "${SAMTOOLS}" index -@ "${THREADS}" "${tmp}"
    mv "${tmp}" "${out}"
    mv "${tmp}.bai" "${out}.bai"
    "${SAMTOOLS}" flagstat -@ "${THREADS}" "${out}" > "${OUTPUT_DIR}/${prefix}.flagstat.txt"

    xs_count="$("${SAMTOOLS}" view -@ "${THREADS}" -c -e 'exists([XS])' "${out}")"
    if [ "${xs_count}" -ne 0 ]; then
        echo "Unexpected XS-tagged alignments in ${out}: ${xs_count}" >&2
        exit 1
    fi
done

echo "completed $(date)"
