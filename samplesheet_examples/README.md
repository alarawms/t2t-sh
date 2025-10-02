# Samplesheet Examples

Example samplesheets for different assembly scenarios.

## File Format

All samplesheets are CSV files with the following columns:

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| `sample` | Yes | Unique sample identifier | `sample1` |
| `hifi_reads` | Yes | Path to PacBio HiFi reads (FASTQ.GZ) | `data/hifi.fastq.gz` |
| `ont_reads` | No | Path to ONT ultra-long reads (FASTQ.GZ) | `data/ont.fastq.gz` |
| `hic_reads_1` | No | Path to Hi-C R1 reads (FASTQ.GZ) | `data/hic_R1.fastq.gz` |
| `hic_reads_2` | No | Path to Hi-C R2 reads (FASTQ.GZ) | `data/hic_R2.fastq.gz` |
| `genome_size` | No | Estimated genome size (k/m/g suffix) | `3g`, `500m`, `4.6m` |

## Examples

### 1. HiFi-only Assembly ([hifi_only.csv](hifi_only.csv))

Basic assembly with PacBio HiFi reads only.

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi_reads.fastq.gz,,,,3g
```

**Use case**: Fast, high-quality assembly when only HiFi data is available.

**Run**:
```bash
nextflow run main.nf -profile docker --input samplesheet_examples/hifi_only.csv --outdir results
```

### 2. HiFi + ONT Assembly ([hifi_ont.csv](hifi_ont.csv))

Assembly with HiFi and Oxford Nanopore ultra-long reads.

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi_reads.fastq.gz,data/ont_reads.fastq.gz,,,3g
```

**Use case**: Improved contiguity and repeat resolution using ONT ultra-long reads (80+ kb).

**Hifiasm flags**: `--ul` for ultra-long integration

**Run**:
```bash
nextflow run main.nf -profile docker --input samplesheet_examples/hifi_ont.csv --outdir results
```

### 3. HiFi + Hi-C Assembly ([hifi_hic.csv](hifi_hic.csv))

Assembly with HiFi and Hi-C reads for phasing.

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi_reads.fastq.gz,,data/hic_R1.fastq.gz,data/hic_R2.fastq.gz,3g
```

**Use case**: Haplotype-resolved assembly with chromosome-level phasing.

**Hifiasm flags**: `--h1`, `--h2` for Hi-C phasing

**Run**:
```bash
nextflow run main.nf -profile docker --input samplesheet_examples/hifi_hic.csv --outdir results
```

### 4. Complete T2T Assembly ([complete_t2t.csv](complete_t2t.csv))

Full telomere-to-telomere assembly with all read types.

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/hifi_reads.fastq.gz,data/ont_reads.fastq.gz,data/hic_R1.fastq.gz,data/hic_R2.fastq.gz,3g
```

**Use case**: Highest quality assembly combining all technologies.

**Hifiasm flags**: `--ul` + `--h1` + `--h2` for complete integration

**Run**:
```bash
nextflow run main.nf -profile kaust --input samplesheet_examples/complete_t2t.csv --outdir results
```

### 5. Multiple Samples ([multi_sample.csv](multi_sample.csv))

Process multiple samples with different read combinations.

```csv
sample,hifi_reads,ont_reads,hic_reads_1,hic_reads_2,genome_size
sample1,data/sample1_hifi.fastq.gz,,,,3g
sample2,data/sample2_hifi.fastq.gz,data/sample2_ont.fastq.gz,,,500m
sample3,data/sample3_hifi.fastq.gz,,data/sample3_hic_R1.fastq.gz,data/sample3_hic_R2.fastq.gz,3g
sample4,data/sample4_hifi.fastq.gz,data/sample4_ont.fastq.gz,data/sample4_hic_R1.fastq.gz,data/sample4_hic_R2.fastq.gz,3.2g
```

**Use case**: Batch processing with different data availability per sample.

**Run**:
```bash
nextflow run main.nf -profile kaust --input samplesheet_examples/multi_sample.csv --outdir results
```

## Read Type Guidelines

### PacBio HiFi (Required)

- **Coverage**: 40-50x recommended, minimum 30x
- **Read length**: 15-20 kb typical
- **Quality**: Q20+ (99% accuracy)
- **Format**: FASTQ.GZ

### Oxford Nanopore (Optional)

- **Coverage**: 30-40x recommended
- **Read length**: 80+ kb (ultra-long preferred)
- **Quality**: Any (Hifiasm handles errors)
- **Format**: FASTQ.GZ
- **Purpose**: Improves contiguity, spans repeats

### Hi-C (Optional)

- **Coverage**: 100-150x recommended
- **Read length**: 150 bp paired-end
- **Format**: Two FASTQ.GZ files (R1 and R2)
- **Purpose**: Chromosome-level phasing, haplotype separation

## Genome Size Format

Use standard suffixes:
- `k` or `K`: kilobases (1,000 bp)
- `m` or `M`: megabases (1,000,000 bp)
- `g` or `G`: gigabases (1,000,000,000 bp)

**Examples**:
- E. coli: `4.6m`
- Yeast: `12m`
- Fruit fly: `140m`
- Human: `3g`
- Wheat: `17g`

## Creating Your Own Samplesheet

1. Copy a template that matches your data:
   ```bash
   cp samplesheet_examples/hifi_ont.csv my_samples.csv
   ```

2. Edit with your file paths:
   ```bash
   nano my_samples.csv
   ```

3. Validate before running:
   ```bash
   nextflow run main.nf --input my_samples.csv --help
   ```

## Notes

- **Paths**: Can be absolute (`/full/path/to/reads.fastq.gz`) or relative (`data/reads.fastq.gz`)
- **Missing reads**: Leave empty (just commas) for optional columns
- **Genome size**: Optional but helps Hifiasm optimize resource usage
- **Sample names**: Must be unique and alphanumeric (use `_` or `-` for separators)

## Troubleshooting

**Error**: "pathspec did not match any file(s)"
- Check file paths are correct
- Ensure paths are accessible from execution environment
- Use absolute paths if running on cluster

**Error**: "Invalid sample name"
- Sample names must match pattern: `^[a-zA-Z0-9_-]+$`
- No spaces or special characters

**Error**: "Hi-C requires both R1 and R2"
- Both `hic_reads_1` and `hic_reads_2` must be provided together
- Cannot provide only one Hi-C file
