# Usage Guide

## Pipeline Execution

### Basic Usage

The pipeline requires:
1. Input samplesheet (CSV format)
2. Output directory path
3. Execution profile (kaust, docker, conda, or singularity)

### Input Samplesheet Format

Create a CSV file with the following columns:

```csv
sample_id,hifi_reads
```

**Example:**
```csv
sample_id,hifi_reads
arabidopsis,/data/hifi/arabidopsis_hifi.fastq.gz
human_chr21,/data/hifi/human_chr21_hifi.fastq.gz
```

**Requirements:**
- `sample_id`: Unique identifier for each sample
- `hifi_reads`: Full path to HiFi FASTQ file (can be gzipped)

## Execution Examples

### KAUST Ibex Cluster

```bash
# Submit to SLURM batch queue
nextflow run main.nf \\
  -profile kaust \\
  --input samples.csv \\
  --outdir /ibex/scratch/$USER/results \\
  --genome_size 3.2g \\
  --busco_lineage eukaryota_odb10

# Resume previous run
nextflow run main.nf -resume -profile kaust --input samples.csv --outdir results
```

**Notes:**
- Uses Singularity containers
- Automatically loads required modules
- Submits jobs to 'batch' partition
- Caches containers in `~/.singularity/nf_images/`

### Local Execution with Docker

```bash
# Standard run
nextflow run main.nf \\
  -profile docker \\
  --input samples.csv \\
  --outdir results \\
  --genome_size 500m \\
  --busco_lineage bacteria_odb10

# With custom resources
nextflow run main.nf \\
  -profile docker \\
  --input samples.csv \\
  --outdir results \\
  --max_cpus 16 \\
  --max_memory 64.GB \\
  --max_time 24.h
```

### Local Execution with Conda

```bash
# First run will create conda environments
nextflow run main.nf \\
  -profile conda \\
  --input samples.csv \\
  --outdir results \\
  --genome_size 3.2g \\
  --busco_lineage eukaryota_odb10
```

**Notes:**
- Environments cached in `work/conda/`
- Initial setup takes ~10-15 minutes
- Subsequent runs use cached environments

## Parameter Details

### Assembly Parameters

#### `--genome_size`
Expected genome size for Hifiasm optimization.

**Format**: Number + unit (k/m/g)
- `500k` = 500 kilobases
- `120m` = 120 megabases
- `3.2g` = 3.2 gigabases

**Example:**
```bash
--genome_size 3.2g  # Human genome
--genome_size 120m  # Arabidopsis
```

#### `--hifiasm_args`
Pass custom arguments directly to Hifiasm.

**Common options:**
- `-l 3` - Purge level (0-3, higher = more aggressive)
- `--primary` - Output primary assembly only
- `--hom-cov 50` - Homozygous coverage cutoff

**Example:**
```bash
--hifiasm_args '-l 2 --hom-cov 40'
```

### Quality Control Parameters

#### `--busco_lineage`
BUSCO lineage dataset for completeness assessment.

**Common lineages:**
- `eukaryota_odb10` - All eukaryotes
- `metazoa_odb10` - Animals
- `vertebrata_odb10` - Vertebrates
- `mammalia_odb10` - Mammals
- `actinopterygii_odb10` - Ray-finned fishes
- `viridiplantae_odb10` - Green plants
- `fungi_odb10` - Fungi
- `bacteria_odb10` - Bacteria

**Auto-download**: Lineages are downloaded automatically on first use.

**Example:**
```bash
--busco_lineage mammalia_odb10
```

#### `--busco_mode`
BUSCO analysis mode (default: `genome`)

**Options:**
- `genome` - Genome assembly analysis
- `transcriptome` - Transcriptome analysis
- `proteins` - Protein sequence analysis

### Resource Management

#### `--max_cpus`
Maximum CPUs per process (default: 32)

```bash
--max_cpus 64  # Allow up to 64 CPUs
```

#### `--max_memory`
Maximum memory per process (default: 128.GB)

```bash
--max_memory 256.GB
```

#### `--max_time`
Maximum runtime per process (default: 48.h)

```bash
--max_time 72.h
```

## Advanced Features

### Resuming Failed Runs

Nextflow caches completed tasks. Use `-resume` to continue:

```bash
nextflow run main.nf -resume -profile docker --input samples.csv
```

**When to use:**
- Pipeline failed mid-execution
- Added more samples to samplesheet
- Changed downstream parameters only

### Work Directory Management

Nextflow stores intermediate files in `work/`:

```bash
# Clean work directory after success
rm -rf work/

# Keep work directory for debugging
# (default behavior)
```

**Disk usage:** Work directory can be 2-3x larger than final results.

### Output Publishing

Control how outputs are published:

```bash
# In nextflow.config
params.publish_dir_mode = 'copy'  // Copy files (default)
params.publish_dir_mode = 'symlink'  // Symlink (saves space)
params.publish_dir_mode = 'move'  // Move files
```

## Monitoring and Reports

### Execution Reports

Pipeline generates several reports in `results/pipeline_info/`:

1. **execution_report.html** - Resource usage statistics
2. **execution_timeline.html** - Task execution timeline
3. **execution_trace.txt** - Detailed task information
4. **pipeline_dag.html** - Workflow visualization

### Real-time Monitoring

Monitor running pipeline:

```bash
# Watch Nextflow log
tail -f .nextflow.log

# Check SLURM queue (on Ibex)
squeue -u $USER

# Monitor resource usage
top -u $USER
```

## Troubleshooting

### Issue: Out of Memory

**Symptom:** Process fails with exit code 137 or "Killed"

**Solution:**
```bash
# Increase max memory
nextflow run main.nf --max_memory 256.GB ...

# Or edit conf/base.config for specific process
```

### Issue: Timeout

**Symptom:** Process fails with "DUE TO TIME LIMIT"

**Solution:**
```bash
# Increase max time
nextflow run main.nf --max_time 96.h ...
```

### Issue: Container Pull Fails

**Symptom:** "Failed to pull Docker image"

**Solution on Ibex:**
```bash
# Singularity will auto-convert and cache
# Ensure internet access from compute nodes
# Or pre-pull containers:
singularity pull docker://quay.io/biocontainers/hifiasm:0.19.9--h2e03b76_0
```

**Solution locally:**
```bash
# Docker: ensure Docker daemon is running
sudo systemctl start docker

# Conda: ensure conda is activated
conda activate base
```

### Issue: BUSCO Lineage Not Found

**Symptom:** "BUSCO dataset not found"

**Solution:**
```bash
# BUSCO auto-downloads lineages
# Ensure internet connection
# Or manually download:
busco --download eukaryota_odb10
```

## Best Practices

### Resource Allocation

**Small genomes (<100 Mb):**
```bash
--max_cpus 8 --max_memory 32.GB --max_time 12.h
```

**Medium genomes (100 Mb - 1 Gb):**
```bash
--max_cpus 32 --max_memory 128.GB --max_time 24.h
```

**Large genomes (>1 Gb):**
```bash
--max_cpus 64 --max_memory 500.GB --max_time 48.h
```

### Scratch vs Project Storage

On KAUST Ibex:

```bash
# Use scratch for active analysis
--outdir /ibex/scratch/$USER/results

# Move final results to project storage
mv /ibex/scratch/$USER/results /ibex/project/
```

### Multiple Samples

Process samples in batches:

```bash
# Create separate samplesheets
# Run batches sequentially or in parallel (different outdirs)

# Batch 1
nextflow run main.nf --input batch1.csv --outdir results_batch1

# Batch 2
nextflow run main.nf --input batch2.csv --outdir results_batch2
```

## Next Steps

After Phase 1 completion:
1. Check BUSCO results for assembly quality
2. Inspect assembly statistics (N50, contiguity)
3. Proceed to Phase 2 (Hi-C scaffolding) if needed

See [outputs.md](outputs.md) for detailed output descriptions.
