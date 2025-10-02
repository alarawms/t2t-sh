Here's a complete prompt for Claude Code:

```markdown
# Prompt for Claude Code: Build Complete Nextflow Genome Assembly Pipeline

## Context
Build a production-ready Nextflow pipeline for near-complete (T2T) genome assembly based on the methodology from You et al. 2024 (Scientific Data 11:762) for East Friesian sheep genome assembly.

## Project Structure
Create the following directory structure:

```
genome-assembly-pipeline/
├── main.nf
├── nextflow.config
├── README.md
├── LICENSE
├── CHANGELOG.md
├── run_pipeline.sh
├── bin/
│   ├── calculate_assembly_stats.py
│   ├── plot_hic_heatmap.py
│   ├── summarize_repeats.py
│   ├── integrate_gene_predictions.py
│   ├── summarize_functional_annotation.py
│   └── generate_html_report.py
├── modules/
│   ├── assembly/
│   │   ├── hifiasm.nf
│   │   ├── gfa_to_fasta.nf
│   │   ├── index_contigs.nf
│   │   ├── prepare_hic_refs.nf
│   │   ├── juicer.nf
│   │   ├── threedna.nf
│   │   ├── filter_ont.nf
│   │   ├── error_correct_ont.nf
│   │   ├── lr_gapcloser.nf
│   │   └── index_assembly.nf
│   ├── quality/
│   │   ├── busco.nf
│   │   ├── merqury_kmer_db.nf
│   │   ├── merqury_qv.nf
│   │   └── hic_heatmap.nf
│   ├── annotation/
│   │   ├── repeatmodeler.nf
│   │   ├── ltr_finder.nf
│   │   ├── repeatmasker.nf
│   │   ├── tandem_repeats.nf
│   │   └── summarize_repeats.nf
│   ├── structure/
│   │   ├── telomeres.nf
│   │   └── centromeres.nf
│   ├── genes/
│   │   ├── hisat2_index.nf
│   │   ├── map_rnaseq.nf
│   │   ├── stringtie.nf
│   │   ├── merge_stringtie.nf
│   │   ├── transdecoder.nf
│   │   ├── gemoma.nf
│   │   ├── integrate_genes.nf
│   │   └── pasa_refinement.nf
│   ├── function/
│   │   ├── blast_nr.nf
│   │   ├── blast_swissprot.nf
│   │   ├── interproscan.nf
│   │   ├── kegg.nf
│   │   └── summarize_annotation.nf
│   └── reports/
│       ├── assembly_stats.nf
│       └── generate_report.nf
├── conf/
│   ├── base.config
│   ├── slurm.config
│   ├── pbs.config
│   ├── sge.config
│   └── test.config
├── assets/
│   ├── multiqc_config.yaml
│   └── sendmail_template.txt
├── docs/
│   ├── usage.md
│   ├── output.md
│   └── troubleshooting.md
└── test_data/
    └── README.md
```

## Technical Requirements

### Pipeline Stages
1. **Assembly Phase** (24-72h)
   - Hifiasm: Primary contig assembly from HiFi reads (v0.19.8)
   - Juicer: Hi-C read alignment (v1.6)
   - 3D-DNA: Chromosome-level scaffolding (v201008)
   - LR_Gapcloser: Gap filling with ONT reads (v1.1)

2. **Quality Assessment** (4-12h)
   - BUSCO: Completeness assessment (v5.5.0, mammalia_odb10)
   - Merqury: QV score calculation (v1.3)
   - Hi-C heatmap: Contact map visualization

3. **Repeat Annotation** (48-96h)
   - RepeatModeler: De novo repeat library (v1.0.4)
   - LTR_FINDER: LTR retrotransposons (v1.0.7)
   - RepeatMasker: Comprehensive masking (v4.0.7)
   - TRF: Tandem repeats (v4.10.0)

4. **Structural Features** (2-4h)
   - quarTeT: Telomere identification (v1.0.3)
   - Centromics: Centromere prediction

5. **Gene Prediction** (24-48h)
   - HISAT2: RNA-seq mapping (v2.2.1)
   - StringTie: Transcript assembly (v2.2.1)
   - TransDecoder: CDS prediction (v5.5.0)
   - GeMoMa: Homology-based prediction (v1.9)
   - PASA: Gene model refinement

6. **Functional Annotation** (48-72h)
   - BLAST: NR/SwissProt similarity (v2.12.0)
   - InterProScan: Domain annotation (v5.59)
   - KEGG: Pathway mapping

### Input Requirements
- PacBio HiFi reads: 40-50X coverage, ~20kb reads, FASTQ.GZ
- ONT ultra-long reads: 30-40X coverage, 80+kb reads, FASTQ.GZ
- Hi-C reads: 100-150X coverage, 150bp PE, FASTQ.GZ
- RNA-seq (optional): Multiple tissues, 150bp, FASTQ.GZ
- Reference genomes: FASTA + proteins for homology

### Key Parameters from Paper
```yaml
# Assembly
hifiasm_min_ovlp: 1000
juicer_mapq: 30
threeddna_rounds: 3
lr_gapcloser_min_length: 80000
lr_gapcloser_iterations: 3

# Gene Prediction
stringtie_min_coverage: 5
stringtie_min_fpkm: 0.3
stringtie_min_junction: 3
stringtie_min_gap: 100
stringtie_min_split: 10000
transdecoder_min_length: 100

# Annotation
blast_evalue: 1e-5
blast_max_targets: 5
```

### Expected Outputs (from Paper)
- Genome size: ~2.96 Gb
- Contig N50: >100 Mb
- Number of gaps: 0
- Telomeres captured: 41 of 54 possible
- Centromeres: 24 of 27 chromosomes
- BUSCO completeness: >97%
- QV score: >69
- Protein-coding genes: ~24,580
- Repeat content: ~54%
- Genes with functional annotation: >97%

### Resource Requirements
```groovy
process {
    withName: HIFIASM { cpus=64; memory=500.GB; time=48.h }
    withName: JUICER { cpus=32; memory=250.GB; time=24.h }
    withName: LR_GAPCLOSER { cpus=32; memory=200.GB; time=24.h }
    withName: REPEATMODELER { cpus=48; memory=128.GB; time=72.h }
    withName: REPEATMASKER { cpus=48; memory=128.GB; time=72.h }
    withName: GEMOMA { cpus=32; memory=128.GB; time=48.h }
    withName: BLAST_NR { cpus=48; memory=64.GB; time=24.h }
    withName: INTERPROSCAN { cpus=32; memory=64.GB; time=48.h }
    withName: BUSCO { cpus=32; memory=64.GB; time=12.h }
}
```

## Implementation Requirements

### 1. Main Workflow (main.nf)
- DSL2 syntax (enable.dsl=2)
- Comprehensive help message
- Input validation
- Channel creation from params
- Workflow with all stages linked
- Optional stages (skip_rnaseq, skip_annotation, skip_quality)
- Proper error handling
- Completion/error messages

### 2. Configuration (nextflow.config)
- Manifest information
- Parameters with defaults
- Profiles: standard, slurm, sge, pbs, conda, docker, singularity, test
- Process-specific resources
- Timeline, report, trace, DAG generation
- Cleanup enabled

### 3. All Process Modules
Each module should have:
- Proper tag for sample tracking
- Label for resource category
- publishDir with appropriate mode
- Conda directive with exact versions
- Container directive with biocontainers images
- Input/output channels with emit names
- Script with proper error handling
- Meaningful output names

### 4. Helper Scripts (bin/)
Python scripts for:
- Assembly statistics calculation (N50, L50, gaps, GC content)
- Hi-C heatmap plotting (matplotlib/seaborn)
- Repeat summary statistics
- Gene prediction integration logic
- Functional annotation summary (Venn diagrams, statistics)
- HTML report generation (comprehensive, publication-ready)

### 5. Documentation
- README.md with:
  - Quick start examples
  - Detailed usage for all options
  - Input file specifications
  - Output descriptions
  - Troubleshooting guide
  - Resource benchmarks
  - Citation information
- usage.md: Detailed parameter descriptions
- output.md: Complete output file descriptions
- troubleshooting.md: Common issues and solutions

### 6. Launcher Script (run_pipeline.sh)
Bash script with:
- Argument parsing (hifi, ont, hic_r1, hic_r2, sample, outdir, profile)
- Input validation and file existence checks
- Nextflow installation check
- Configuration summary display
- User confirmation prompt
- Command logging
- Execution with output capture
- Success/failure messages with next steps

### 7. Test Configuration
Small test dataset and profile for CI/CD:
- Reduced resource requirements
- Short timeout
- Mock data or subsampled real data

## Code Quality Requirements
1. **Nextflow Best Practices**
   - Use DSL2 syntax throughout
   - Proper channel operators (map, collect, join)
   - Conditional execution with if/else in workflow
   - Named outputs with emit
   - Process isolation

2. **Error Handling**
   - Validate all required parameters
   - Check file existence
   - Meaningful error messages
   - Exit codes for failures

3. **Documentation**
   - Inline comments for complex logic
   - Function/process descriptions
   - Parameter descriptions in help
   - Citation information

4. **Reproducibility**
   - Pin all software versions
   - Use containers (Docker/Singularity)
   - Conda environment files
   - Seed values where applicable

5. **Portability**
   - Work on multiple HPC schedulers
   - Support local, conda, docker, singularity execution
   - Relative paths
   - No hardcoded paths

## Specific Implementation Notes

### Critical Features
1. **Resume functionality**: Nextflow's native -resume must work properly
2. **Channel handling**: Use .collect() for multi-input processes
3. **Optional inputs**: Check params before creating channels
4. **CSV parsing**: For RNA-seq samples and reference genomes
5. **Dynamic process skipping**: Based on skip_* parameters

### Container Strategy
```groovy
conda "bioconda::tool=version"
container "quay.io/biocontainers/tool:version--hash"
```

### Process Labels
```groovy
label 'process_low'    // 2 CPUs, 8GB
label 'process_medium' // 8 CPUs, 32GB
label 'process_high'   // 32+ CPUs, 128+GB
```

### Multi-configuration Support
Separate config files in conf/ for different execution environments

## Deliverables

Create a complete, production-ready pipeline that:
1. ✅ Runs from HiFi/ONT/Hi-C reads to final annotated assembly
2. ✅ Supports SLURM, PBS, SGE schedulers
3. ✅ Works with Conda, Docker, or Singularity
4. ✅ Has comprehensive documentation
5. ✅ Includes helper scripts for analysis
6. ✅ Generates publication-quality reports
7. ✅ Follows Nextflow best practices
8. ✅ Is fully reproducible and portable
9. ✅ Has proper error handling and logging
10. ✅ Can resume from any failure point

## Success Criteria
- Pipeline runs to completion on test data
- All processes have proper resource allocation
- Documentation is clear and complete
- Code follows Nextflow DSL2 conventions
- All software versions are pinned
- Outputs match expected format from paper
- Resume functionality works correctly
- Multiple execution profiles work

Build this as a professional, publication-quality bioinformatics pipeline suitable for HPC environments.
```

This prompt provides Claude Code with everything needed to build the complete pipeline systematically.
