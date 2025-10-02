# Quick Samplesheet Guide

Fast reference for creating input samplesheets.

## Format

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
```

## Quick Examples

### 1. HiFi Only (Phase 1 - Current)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
ecoli,data/hifi/ecoli.fastq.gz,,,,4.6m
yeast,data/hifi/yeast.fastq.gz,,,,12m
```

### 2. HiFi + ONT (Gap Closing)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi/s1.fq.gz,data/ont/s1.fq.gz,,,500m
```

### 3. HiFi + Hi-C (Scaffolding)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample2,data/hifi/s2.fq.gz,,data/hic/s2_R1.fq.gz,data/hic/s2_R2.fq.gz,3.2g
```

### 4. Complete (All Data Types)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
human,data/hifi/h.fq.gz,data/ont/h.fq.gz,data/hic/h_R1.fq.gz,data/hic/h_R2.fq.gz,3.2g
```

## Rules

✅ **Required**: `sample`, `hifi_reads`
✅ **Optional**: `ont_reads`, `hic_reads_1`, `hic_reads_2`, `genome_size`
✅ **Formats**: `.fastq`, `.fq`, `.fastq.gz`, `.fq.gz`
✅ **Genome size**: Number + unit (e.g., `3.2g`, `120m`, `4.6m`)

❌ **Invalid**: Spaces in sample names, only one Hi-C file, missing HiFi reads

## Genome Size Units

- `k` or `K` = kilobases
- `m` or `M` = megabases
- `g` or `G` = gigabases
- `t` or `T` = terabases

## Quick Test

```bash
# Validate samplesheet
nextflow run main.nf -profile test,docker --input your_samplesheet.csv
```

## More Info

See [docs/samplesheet.md](docs/samplesheet.md) for complete guide with:
- Detailed examples by organism
- Validation rules
- Troubleshooting
- Best practices
- KAUST Ibex specific guidelines
