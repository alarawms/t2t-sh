# Samplesheet Guide

Complete guide for creating input samplesheets for the T2T assembly pipeline.

## Format

The pipeline uses CSV (Comma-Separated Values) format with the following columns:

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
```

## Column Descriptions

### Required Columns

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| **sample** | string | Unique sample identifier (no spaces) | `sample1`, `human_chr21` |
| **hifi_reads** | path | Path to PacBio HiFi reads (FASTQ/FQ, gzipped or not) | `/data/hifi/sample1.fastq.gz` |

### Optional Columns

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| **ont_reads** | path | Path to Oxford Nanopore reads for gap closing | `/data/ont/sample1.fastq.gz` |
| **hic_reads_1** | path | Path to Hi-C forward reads (R1) | `/data/hic/sample1_R1.fastq.gz` |
| **hic_reads_2** | path | Path to Hi-C reverse reads (R2) | `/data/hic/sample1_R2.fastq.gz` |
| **genome_size** | string | Expected genome size (with unit: k, m, g, t) | `3.2g`, `120m`, `4.6m` |

## Usage Scenarios

### Scenario 1: HiFi Only (Phase 1 - Current)

Minimal samplesheet for basic HiFi assembly:

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
ecoli,/data/hifi/ecoli.fastq.gz,,,,4.6m
arabidopsis,/data/hifi/arabidopsis.fastq.gz,,,,120m
human,/data/hifi/human.fastq.gz,,,,3.2g
```

**Use case**: Quick assembly, bacteria, small genomes
**Output**: Primary and alternate contigs from Hifiasm

---

### Scenario 2: HiFi + ONT (Gap Closing)

Add ONT reads for gap closing in complex regions:

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,/data/hifi/s1.fastq.gz,/data/ont/s1.fastq.gz,,,500m
sample2,/data/hifi/s2.fastq.gz,/data/ont/s2.fastq.gz,,,3.2g
```

**Use case**: Complex genomes with repetitive regions
**Output**: HiFi assembly + ONT-based gap closing
**Note**: Requires Phase 2 implementation

---

### Scenario 3: HiFi + Hi-C (Chromosome Scaffolding)

Add Hi-C data for chromosome-level scaffolding:

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,/data/hifi/s1.fq.gz,,/data/hic/s1_R1.fq.gz,/data/hic/s1_R2.fq.gz,3.2g
sample2,/data/hifi/s2.fq.gz,,/data/hic/s2_R1.fq.gz,/data/hic/s2_R2.fq.gz,120m
```

**Use case**: Chromosome-level assembly, T2T genomes
**Output**: HiFi assembly + Hi-C scaffolding
**Note**: Requires Phase 2 implementation

---

### Scenario 4: Complete T2T Assembly (All Data Types)

Full dataset for telomere-to-telomere assembly:

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
human_chr21,/data/hifi/h21.fastq.gz,/data/ont/h21.fastq.gz,/data/hic/h21_R1.fastq.gz,/data/hic/h21_R2.fastq.gz,46.7m
mouse,/data/hifi/mouse.fastq.gz,/data/ont/mouse.fastq.gz,/data/hic/mouse_R1.fastq.gz,/data/hic/mouse_R2.fastq.gz,2.7g
```

**Use case**: High-quality reference genomes, T2T assemblies
**Output**: Complete pipeline with assembly, scaffolding, and gap closing
**Note**: Requires Phase 2 & 3 implementation

---

### Scenario 5: Mixed Datasets

Different samples with different data availability:

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
bacteria1,/data/hifi/bac1.fq.gz,,,,4.6m
plant1,/data/hifi/plant1.fq.gz,/data/ont/plant1.fq.gz,,,120m
animal1,/data/hifi/animal1.fq.gz,,/data/hic/animal1_R1.fq.gz,/data/hic/animal1_R2.fq.gz,500m
reference1,/data/hifi/ref1.fq.gz,/data/ont/ref1.fq.gz,/data/hic/ref1_R1.fq.gz,/data/hic/ref1_R2.fq.gz,3.2g
```

**Use case**: Batch processing with varying data types
**Output**: Pipeline adapts to available data per sample

---

## File Path Guidelines

### Absolute vs Relative Paths

**Absolute paths** (recommended for SLURM):
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,/ibex/scratch/user/data/hifi.fastq.gz,,,,3.2g
```

**Relative paths** (local execution):
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi.fastq.gz,,,,3.2g
```

### Supported File Extensions

- `.fastq` or `.fq` (uncompressed)
- `.fastq.gz` or `.fq.gz` (gzip compressed - recommended)

**Note**: All files will be automatically handled, no decompression needed.

---

## Genome Size Specification

### Format: `<number><unit>`

**Units**:
- `k` or `K` = kilobases (1,000 bp)
- `m` or `M` = megabases (1,000,000 bp)
- `g` or `G` = gigabases (1,000,000,000 bp)
- `t` or `T` = terabases (1,000,000,000,000 bp)

**Examples**:
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
ecoli,data/ecoli.fq.gz,,,,4.6m
yeast,data/yeast.fq.gz,,,,12m
arabidopsis,data/arab.fq.gz,,,,120m
fruit_fly,data/fly.fq.gz,,,,140m
mouse,data/mouse.fq.gz,,,,2.7g
human,data/human.fq.gz,,,,3.2g
```

**Why specify genome size?**
- Optimizes Hifiasm memory usage
- Helps with coverage estimation
- Improves assembly parameters

---

## Validation

The pipeline automatically validates your samplesheet:

### ✅ Valid Examples

```csv
# Minimal (Phase 1)
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
test,data/test.fastq.gz,,,,10m

# HiFi + ONT
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi.fq.gz,data/ont.fq.gz,,,500m

# HiFi + Hi-C (both R1 and R2 required)
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample2,data/hifi.fq.gz,,data/hic_R1.fq.gz,data/hic_R2.fq.gz,3.2g
```

### ❌ Invalid Examples

```csv
# Missing required HiFi reads
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,,,,,3.2g

# Sample name with spaces
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
my sample,data/hifi.fq.gz,,,,3.2g

# Only one Hi-C file (need both R1 and R2)
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample3,data/hifi.fq.gz,,data/hic_R1.fq.gz,,3.2g

# Invalid genome size format
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample4,data/hifi.fq.gz,,,,3.2 gb
```

---

## Creating Samplesheets

### Method 1: Manual (Excel/Text Editor)

1. Open Excel or text editor
2. Create header row: `sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size`
3. Add one row per sample
4. Save as CSV format
5. Verify no quotes or extra commas

### Method 2: Command Line

```bash
# Create header
echo "sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size" > samplesheet.csv

# Add samples
echo "sample1,/data/hifi/s1.fastq.gz,,,3.2g" >> samplesheet.csv
echo "sample2,/data/hifi/s2.fastq.gz,/data/ont/s2.fastq.gz,,500m" >> samplesheet.csv
```

### Method 3: Script (Multiple Samples)

```bash
#!/bin/bash
# Generate samplesheet from file list

echo "sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size" > samplesheet.csv

for hifi_file in /data/hifi/*.fastq.gz; do
    sample=$(basename "$hifi_file" .fastq.gz)
    echo "${sample},${hifi_file},,,,3.2g" >> samplesheet.csv
done
```

---

## Testing Your Samplesheet

### Quick Validation

```bash
# Run with test profile to validate samplesheet
nextflow run main.nf \
  -profile test,docker \
  --input your_samplesheet.csv \
  --outdir test_results
```

### Check File Paths

```bash
# Verify all files exist
awk -F',' 'NR>1 {
    if ($2 != "") system("ls -lh " $2);
    if ($3 != "") system("ls -lh " $3);
    if ($4 != "") system("ls -lh " $4);
    if ($5 != "") system("ls -lh " $5);
}' samplesheet.csv
```

---

## Examples by Organism

### Bacteria (E. coli)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
ecoli_k12,/data/hifi/ecoli.fq.gz,,,,4.6m
```
**Coverage needed**: 30-50x HiFi

### Yeast (S. cerevisiae)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
yeast,/data/hifi/yeast.fq.gz,,,,12m
```
**Coverage needed**: 30-50x HiFi

### Plant (Arabidopsis)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
arabidopsis,/data/hifi/arab.fq.gz,/data/ont/arab.fq.gz,/data/hic/arab_R1.fq.gz,/data/hic/arab_R2.fq.gz,120m
```
**Coverage needed**: 40-60x HiFi, 20x ONT, 50x Hi-C

### Mammal (Human)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
human,/data/hifi/human.fq.gz,/data/ont/human.fq.gz,/data/hic/human_R1.fq.gz,/data/hic/human_R2.fq.gz,3.2g
```
**Coverage needed**: 30-40x HiFi, 30x ONT, 50-100x Hi-C

---

## Troubleshooting

### Error: "HiFi reads are required"
**Solution**: Ensure `hifi_reads` column is filled for every sample

### Error: "Both Hi-C read pairs must be provided"
**Solution**: Provide both `hic_reads_1` AND `hic_reads_2`, or leave both empty

### Error: "File does not exist"
**Solution**: Verify file paths are correct and files are accessible

### Error: "Sample name cannot contain spaces"
**Solution**: Use underscores or hyphens: `my_sample` not `my sample`

### Error: "Invalid genome size format"
**Solution**: Use format like `3.2g`, `120m`, `4.6m` (number + unit)

---

## Best Practices

1. **Use absolute paths** on HPC systems (KAUST Ibex)
2. **Compress reads** with gzip to save space
3. **Descriptive sample names**: Use meaningful identifiers
4. **Consistent naming**: Follow same pattern for all samples
5. **Test first**: Run with small dataset before full analysis
6. **Document metadata**: Keep separate file with sample information
7. **Version control**: Track samplesheet changes in git

---

## Quick Reference

### Minimal Samplesheet (Current Phase 1)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
test,data/hifi.fastq.gz,,,,3.2g
```

### Full Samplesheet (Future Phases)
```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
complete,data/hifi.fq.gz,data/ont.fq.gz,data/hic_R1.fq.gz,data/hic_R2.fq.gz,3.2g
```

### Template
See [assets/samplesheet_examples.csv](../assets/samplesheet_examples.csv) for more examples.

---

**For more help**: See [docs/usage.md](usage.md) or open an issue on GitHub.
