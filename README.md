# BAM filter

Filter BAM files and create indexed, high-confidence primary BAMs.

## MAPQ primary filtering

```bash
SAMTOOLS=/path/to/samtools \
./filter_bams.sh INPUT_DIR OUTPUT_DIR [MAPQ=30] [THREADS=2]
```

The command uses:

```text
samtools view -q 30 -F 2308
```

- `-q 30`: retain alignments with MAPQ at least 30. This is an aligner-dependent high-confidence filter, not a strict unique-mapping filter.
- `-F 2308`: remove unmapped, secondary, and supplementary alignments; retain primary alignments.
- PCR duplicates are retained.
- Each output is named `<sample>.unique.bam` and is accompanied by `.bai` and `.flagstat.txt` files.
- Input BAMs are retained.

Filtering is applied per alignment record. The script does not require proper pairs and does not repair paired-end mates after filtering.

## Bowtie2 MAPQ plus no-XS filtering

For Bowtie2 BAMs, additionally discard primary alignments carrying the `XS:i` tag:

```bash
SAMTOOLS=/path/to/samtools \
./filter_bowtie2_no_xs.sh INPUT_DIR OUTPUT_DIR [MAPQ=30] [THREADS=2]
```

This uses:

```text
samtools view -q 30 -F 2308 -e '!exists([XS])'
```

Bowtie2 uses `XS:i` for the score of the best alternative alignment it found. Its absence therefore means that Bowtie2 did not report evidence of another valid alignment during its heuristic search; it is stronger than MAPQ filtering alone, but is not an exhaustive proof of genomic uniqueness. Outputs are named `<sample>.mapq30.noXS.bam` and are accompanied by `.bai` and `.flagstat.txt` files. Input BAMs are retained.
