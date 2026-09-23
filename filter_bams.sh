#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 || $# > 4 )); then
    echo "Usage: $0 INPUT_DIR OUTPUT_DIR [MAPQ=30] [THREADS=2]" >&2
    exit 2
fi

input_dir="$1"
output_dir="$2"
mapq="${3:-30}"
threads="${4:-2}"
samtools="${SAMTOOLS:-samtools}"

mkdir -p "$output_dir"

for bam in "$input_dir"/*.bam; do
    if [[ ! -e "$bam" ]]; then
        echo "No BAM files found in $input_dir" >&2
        exit 1
    fi

    sample="$(basename "$bam" .bam)"
    prefix="$output_dir/$sample.unique"
    output="$prefix.bam"

    echo "[filter] $sample"
    "$samtools" view \
        -@ "$threads" \
        -b -q "$mapq" -F 2308 \
        -o "$output" "$bam"

    "$samtools" index -@ "$threads" "$output"
    "$samtools" flagstat -@ "$threads" "$output" \
        > "$prefix.flagstat.txt"
done

echo "completed"
