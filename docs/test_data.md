# Test Data Guide

This guide explains how to obtain test data for validating the T2T assembly pipeline.

## Quick Start

```bash
# Option 1: Tiny test data (fastest, ~1 minute)
./bin/download_test_data.sh tiny

# Option 2: Real E. coli data (requires SRA toolkit, ~10 minutes)
./bin/download_test_data.sh ecoli

# Option 3: Download all
./bin/download_test_data.sh all
```

## Test Dataset Options

### 1. Tiny Test Data (Recommended for CI/CD)

**Source**: Hifiasm release test data
**Size**: 2 Megabases (~5MB compressed)
**Download Time**: ~1 minute
**Assembly Time**: ~2-5 minutes

```bash
./bin/download_test_data.sh tiny
```

**Use Case**:
- Quick pipeline validation
- CI/CD testing
- Development and debugging
- Learning the pipeline

**Expected Results**:
- Assembly completes successfully
- Generates GFA and FASTA outputs
- BUSCO will have limited results (too small)

---

### 2. E. coli K12 HiFi Reads (Real Data)

**Source**: SRA accession SRR10971019
**Genome Size**: 4.6 Mb
**Coverage**: ~150x
**Size**: ~500 MB (full), ~50 MB (subsampled)
**Download Time**: ~5-10 minutes
**Assembly Time**: ~30-60 minutes

```bash
# Requires SRA toolkit
conda install -c bioconda sra-tools

./bin/download_test_data.sh ecoli
```

**Use Case**:
- Full pipeline validation
- Realistic assembly testing
- BUSCO testing with bacteria_odb10
- Resource usage benchmarking

**Expected Results**:
- High-quality closed circular genome
- BUSCO completeness >95% (with bacteria_odb10)
- N50 >4 Mb (closed genome)

---

### 3. Simulated HiFi Reads

**Source**: Generated with pbsim3
**Customizable**: Yes (coverage, error rate, read length)
**Size**: Depends on parameters
**Generation Time**: ~5-10 minutes

```bash
# Requires pbsim3
conda install -c bioconda pbsim3

./bin/download_test_data.sh simulate
```

**Use Case**:
- Controlled testing conditions
- Testing error handling
- Custom genome size testing

---

### 4. Public PacBio Datasets

**Source**: PacBio official datasets
**Options**:
- **Yeast** (~500 MB, 12 Mb genome)
- **Drosophila** (~5 GB, 140 Mb genome)
- **Human HG002** (~30 GB, 3.2 Gb genome)

**Access**: https://www.pacb.com/connect/datasets/

**Use Case**:
- Production-scale testing
- Complex eukaryotic genomes
- Publication-quality assemblies

---

## Manual Download Instructions

### From SRA (Sequence Read Archive)

```bash
# Install SRA toolkit
conda install -c bioconda sra-tools

# Configure SRA toolkit (first time only)
vdb-config --interactive

# Download specific dataset
fastq-dump --split-files --gzip SRR10971019

# Or use faster fasterq-dump
fasterq-dump SRR10971019 --threads 4
gzip SRR10971019.fastq
```

### From PacBio

1. Visit https://www.pacb.com/connect/datasets/
2. Select desired organism
3. Download HiFi reads (FASTQ format)
4. Create samplesheet CSV

### From European Nucleotide Archive (ENA)

```bash
# Download from ENA (often faster than SRA)
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR109/019/SRR10971019/SRR10971019.fastq.gz
```

---

## Creating Custom Samplesheets

### Format

```csv
sample_id,hifi_reads
```

### Examples

**Single sample:**
```csv
sample_id,hifi_reads
ecoli_test,/path/to/test_data/ecoli_hifi.fastq.gz
```

**Multiple samples:**
```csv
sample_id,hifi_reads
sample1,/data/hifi/sample1.fastq.gz
sample2,/data/hifi/sample2.fastq.gz
sample3,/data/hifi/sample3.fastq.gz
```

### Path Requirements

- Paths can be absolute or relative
- Files must exist and be readable
- Supported formats: `.fastq`, `.fastq.gz`, `.fq`, `.fq.gz`

---

## Testing the Pipeline

### With Tiny Data

```bash
# Quick validation
nextflow run main.nf \\
  -profile test,docker \\
  --input test_data/samplesheet_test.csv \\
  --outdir results_test
```

### With E. coli Data

```bash
# Full validation with BUSCO
nextflow run main.nf \\
  -profile docker \\
  --input test_data/samplesheet_test_ecoli.csv \\
  --outdir results_ecoli \\
  --genome_size 4.6m \\
  --busco_lineage bacteria_odb10
```

### On KAUST Ibex

```bash
# Submit to SLURM
nextflow run main.nf \\
  -profile kaust \\
  --input test_data/samplesheet_test_ecoli.csv \\
  --outdir /ibex/scratch/$USER/results_test \\
  --genome_size 4.6m \\
  --busco_lineage bacteria_odb10
```

---

## Expected Outputs

### File Structure

```
results/
├── hifiasm/
│   └── sample_id.gfa
├── fasta/
│   └── sample_id.fasta
├── busco/
│   └── sample_id-busco/
│       └── short_summary.*.txt
└── pipeline_info/
```

### Quality Metrics

**E. coli K12 (expected):**
- Assembly size: ~4.6 Mb
- N50: >4 Mb (circular)
- BUSCO (bacteria_odb10): >95% complete
- Contigs: 1 (closed genome)

**Tiny test data (expected):**
- Assembly size: ~2 Mb
- N50: Variable
- BUSCO: Limited (too small for meaningful results)
- Contigs: Multiple fragments

---

## Troubleshooting

### SRA Toolkit Issues

**Problem**: "vdb-config: command not found"
```bash
# Solution: Install SRA toolkit
conda install -c bioconda sra-tools
```

**Problem**: "Failed to resolve accession"
```bash
# Solution: Configure SRA toolkit
vdb-config --interactive
# Enable remote access in "NETWORK" tab
```

**Problem**: Download very slow
```bash
# Solution: Use ENA instead
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/[path]
```

### Download Script Issues

**Problem**: "wget: command not found"
```bash
# Solution: Install wget
# Ubuntu/Debian: sudo apt-get install wget
# macOS: brew install wget
# Or use curl instead of wget in script
```

**Problem**: Permission denied
```bash
# Solution: Make script executable
chmod +x bin/download_test_data.sh
```

### Disk Space

**Check available space:**
```bash
df -h test_data/
```

**Space requirements:**
- Tiny data: ~10 MB
- E. coli subsampled: ~100 MB
- E. coli full: ~1 GB (including work dir)
- Large genomes: >50 GB

---

## Recommended Test Strategy

### Phase 1: Quick Validation
```bash
# Use tiny data to verify installation
./bin/download_test_data.sh tiny
nextflow run main.nf -profile test,docker
```

### Phase 2: Real Data Validation
```bash
# Use E. coli to test full pipeline
./bin/download_test_data.sh ecoli
nextflow run main.nf -profile docker --input test_data/samplesheet_test_ecoli.csv
```

### Phase 3: Production Testing
```bash
# Test with your target organism data
# Use appropriate BUSCO lineage
nextflow run main.nf -profile kaust --input your_samples.csv
```

---

## Additional Resources

### Public Repositories

- **SRA**: https://www.ncbi.nlm.nih.gov/sra
- **ENA**: https://www.ebi.ac.uk/ena
- **PacBio**: https://www.pacb.com/connect/datasets/
- **Genome Ark**: https://www.genomeark.org/

### Search Tips

**Finding HiFi datasets on SRA:**
```
Search: "pacbio hifi" AND "genome assembly" AND bacteria[organism]
```

**Finding by organism:**
```
Search: "escherichia coli"[organism] AND "pacbio"[platform]
Filter: Library Strategy = WGS
```

### File Format Notes

**HiFi reads characteristics:**
- Typical read length: 10-25 Kb
- Accuracy: >99.9% (Q20+)
- Format: FASTQ with quality scores
- Coverage needed: 30-50x for most genomes

---

## Citation

If you use these test datasets, please cite:

**E. coli SRR10971019**:
- De Maio et al. (2019) "Comparison of long-read sequencing technologies in interrogating bacteria and fly genomes"

**Hifiasm test data**:
- Cheng et al. (2021) "Haplotype-resolved de novo assembly using phased assembly graphs with hifiasm"

**PacBio datasets**:
- Check individual dataset pages for proper citation
