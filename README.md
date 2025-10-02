# T2T Genome Assembly Pipeline

> **Phase 1**: Core assembly pipeline with HiFi reads and BUSCO quality assessment

A production-grade Nextflow pipeline for telomere-to-telomere (T2T) genome assembly, optimized for KAUST Ibex HPC and local execution.

## Quick Start

### Prerequisites

- [Nextflow](https://www.nextflow.io/) ≥23.10.0
- One of: Docker, Singularity, or Conda
- HiFi sequencing reads (PacBio)

### Installation

```bash
# Clone repository
git clone https://github.com/alarawms/t2t-sh.git
cd t2t-sh

# Test installation
nextflow run main.nf -profile test,docker
```

## Usage

### 1. Prepare Input Samplesheet

Create a CSV file with your samples:

```csv
sample_id,hifi_reads
sample1,/path/to/hifi_reads_1.fastq.gz
sample2,/path/to/hifi_reads_2.fastq.gz
```

### 2. Run Pipeline

#### On KAUST Ibex (SLURM)

```bash
nextflow run main.nf \\
  -profile kaust \\
  --input samples.csv \\
  --outdir results \\
  --genome_size 3.2g \\
  --busco_lineage eukaryota_odb10
```

#### Locally with Docker

```bash
nextflow run main.nf \\
  -profile docker \\
  --input samples.csv \\
  --outdir results \\
  --genome_size 3.2g \\
  --busco_lineage eukaryota_odb10
```

#### Locally with Conda

```bash
nextflow run main.nf \\
  -profile conda \\
  --input samples.csv \\
  --outdir results \\
  --genome_size 3.2g \\
  --busco_lineage eukaryota_odb10
```

## Pipeline Overview

### Phase 1 Workflow

```
HiFi Reads → Hifiasm Assembly → GFA to FASTA → BUSCO QC → Results
```

**Modules:**
1. **Hifiasm**: Haplotype-resolved genome assembly
2. **GFA to FASTA**: Convert assembly format for downstream analysis
3. **BUSCO**: Genome completeness assessment

## Parameters

### Required

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to input CSV samplesheet |
| `--outdir` | Output directory for results |

### Assembly Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--genome_size` | `null` | Expected genome size (e.g., '3.2g') |
| `--hifiasm_args` | `''` | Additional hifiasm arguments |

### Quality Control

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--busco_lineage` | `null` | BUSCO lineage dataset (e.g., 'eukaryota_odb10') |
| `--busco_mode` | `'genome'` | BUSCO analysis mode |

### Resource Limits

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max_cpus` | `32` | Maximum CPUs per process |
| `--max_memory` | `'128.GB'` | Maximum memory per process |
| `--max_time` | `'48.h'` | Maximum time per process |

## Profiles

### Execution Profiles

- **`kaust`**: KAUST Ibex SLURM cluster with Singularity
- **`docker`**: Local execution with Docker
- **`conda`**: Local execution with Conda
- **`singularity`**: Local execution with Singularity
- **`test`**: Minimal test dataset

### Example Combinations

```bash
# KAUST Ibex
nextflow run main.nf -profile kaust --input samples.csv

# Local Docker
nextflow run main.nf -profile docker --input samples.csv

# Test with Docker
nextflow run main.nf -profile test,docker
```

## Output Structure

```
results/
├── hifiasm/
│   ├── sample1.gfa              # Assembly graph
│   ├── sample1.p_ctg.gfa        # Primary contigs
│   └── sample1.a_ctg.gfa        # Alternate contigs
├── fasta/
│   └── sample1.fasta            # Converted assembly
├── busco/
│   └── sample1-busco/
│       └── short_summary.*.txt  # BUSCO results
└── pipeline_info/
    ├── execution_report.html    # Execution report
    └── execution_timeline.html  # Timeline visualization
```

## BUSCO Lineages

Common BUSCO lineage datasets:

- `eukaryota_odb10` - Eukaryotes
- `metazoa_odb10` - Animals
- `vertebrata_odb10` - Vertebrates
- `mammalia_odb10` - Mammals
- `viridiplantae_odb10` - Plants
- `fungi_odb10` - Fungi
- `bacteria_odb10` - Bacteria

Find more at [BUSCO datasets](https://busco-data.ezlab.org/v5/data/lineages/).

## Resource Requirements

### Typical Assembly (3Gb genome)

- **CPUs**: 32-64
- **Memory**: 128-500 GB
- **Time**: 24-48 hours
- **Storage**: ~500 GB

### KAUST Ibex Nodes

The pipeline automatically adapts to Ibex resource limits:
- Max CPUs: 1,300
- Max Memory: 16 TB
- Max Time: 14 days

## Troubleshooting

### Common Issues

**Problem**: "ERROR: --input is required!"
```bash
# Solution: Provide input samplesheet
nextflow run main.nf --input samples.csv --outdir results
```

**Problem**: Hifiasm runs out of memory
```bash
# Solution: Increase memory allocation
# Edit nextflow.config or use --max_memory
nextflow run main.nf --max_memory 256.GB ...
```

**Problem**: BUSCO lineage not found
```bash
# Solution: BUSCO will auto-download lineages on first run
# Ensure internet connection or pre-download datasets
```

## Advanced Usage

### Resume Failed Runs

```bash
# Use -resume to continue from last checkpoint
nextflow run main.nf -resume -profile docker --input samples.csv
```

### Custom Hifiasm Parameters

```bash
# Pass custom arguments to hifiasm
nextflow run main.nf \\
  --hifiasm_args '-l 3 --primary' \\
  --input samples.csv
```

### Disable BUSCO

```bash
# Run without BUSCO (faster testing)
nextflow run main.nf --busco_lineage null --input samples.csv
```

## Development Roadmap

- [x] **Phase 1**: Core assembly (Hifiasm + BUSCO) ← Current
- [ ] **Phase 2**: Hi-C scaffolding (Juicer + 3D-DNA + Gap closing)
- [ ] **Phase 3**: Annotation (RepeatMasker + Gene prediction)
- [ ] **Phase 4**: Production polish (Docs + CI/CD + Benchmarks)

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## Citation

If you use this pipeline, please cite:

- **Hifiasm**: Cheng et al. (2021) Nature Methods
- **BUSCO**: Manni et al. (2021) Molecular Biology and Evolution
- **Nextflow**: Di Tommaso et al. (2017) Nature Biotechnology

## License

MIT License - see [LICENSE](LICENSE) for details

## Support

- **Issues**: [GitHub Issues](https://github.com/alarawms/t2t-sh/issues)
- **KAUST HPC**: [docs.hpc.kaust.edu.sa](https://docs.hpc.kaust.edu.sa)
- **Nextflow**: [nextflow.io](https://www.nextflow.io/)

---

**Current Version**: 0.1.0 (Phase 1)
**Last Updated**: October 2025
