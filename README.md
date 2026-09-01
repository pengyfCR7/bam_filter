# BAM filter

Filter every BAM in one directory and create indexed, high-confidence primary BAMs in another directory.

```bash
SAMTOOLS=/path/to/samtools \
./filter_bams.sh INPUT_DIR OUTPUT_DIR [MAPQ=30] [THREADS=2]
```

The command uses:

```text
samtools view -q 30 -F 2308
```

- `-q 30`: retain alignments with MAPQ at least 30. This is an aligner-dependent proxy for unique/high-confidence mapping.
- `-F 2308`: remove unmapped, secondary, and supplementary alignments; retain primary alignments.
- PCR duplicates are retained.
- Each output is named `<sample>.unique.bam` and is accompanied by `.bai`, `.flagstat.txt`, and `.filter_counts.json` files.
- The JSON file records the number of processed, accepted, and rejected alignments without rereading the input BAM.
- Existing complete BAM/index pairs are skipped.

Filtering is applied per alignment record. The script does not require proper pairs and does not repair paired-end mates after filtering.
