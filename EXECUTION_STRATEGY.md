# Genome Assembly Pipeline - Practical Execution Strategy

> **Engineering Philosophy**: Simple, modular, production-ready. Build incrementally, test continuously, use real-world tools.

## 🎯 Project Goals

Build a **production-grade Nextflow pipeline** for T2T (telomere-to-telomere) genome assembly based on You et al. 2024, following **nf-core best practices** with emphasis on:

1. **Simplicity**: No over-engineering, clear structure
2. **Modularity**: Reusable nf-core style modules
3. **Reproducibility**: Containers + version pinning
4. **Maintainability**: Clear documentation, standard patterns

---

## 📊 Research Findings (October 2025)

### Nextflow Ecosystem
- **Current Standard**: DSL2 with nf-core conventions
- **Module Repository**: 1,608+ modules in nf-core/modules
- **Best Practice**: Use existing nf-core modules when available
- **Community**: 2,602+ GitHub contributors, active Slack

### Tool Versions (Latest Verified)
| Tool | Current Version | Status | Container Available |
|------|----------------|--------|---------------------|
| Hifiasm | 0.19.9+ (ONT support added) | ✅ Active | Yes - BioContainers |
| BUSCO | 5.5.0+ | ✅ Stable | Yes - nf-core module |
| HISAT2 | 2.2.1+ | ✅ Stable | Yes - nf-core module |
| StringTie | 2.2.3+ | ✅ Stable | Yes - nf-core module |
| Juicer | 1.6+ | ✅ Stable | Yes - BioContainers |
| RepeatMasker | 4.1.5+ | ✅ Active | Yes - BioContainers |
| Merqury | 1.3+ | ✅ Stable | Yes - BioContainers |

### Key nf-core Patterns
```groovy
// Modern module structure
process MODULE_NAME {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::tool=version"
    container "quay.io/biocontainers/tool:version--hash"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.output"), emit: results
    path "versions.yml",               emit: versions

    script:
    """
    tool_command \\
        --input ${reads} \\
        --threads ${task.cpus} \\
        > output.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tool: \$(tool --version | head -1)
    END_VERSIONS
    """
}
```

---

## 🏗️ Simplified Architecture

### Directory Structure (Minimal, Scalable)
```
t2t-assembly-pipeline/
├── main.nf                    # Entry point workflow
├── nextflow.config            # Main configuration
├── modules/
│   ├── local/                 # Custom modules
│   │   ├── hifiasm.nf
│   │   ├── lr_gapcloser.nf
│   │   └── threedna.nf
│   └── nf-core/              # Reused nf-core modules (git submodule)
│       ├── busco/
│       ├── hisat2/
│       └── stringtie/
├── subworkflows/             # Logical groupings
│   ├── assembly.nf           # Hifiasm → Juicer → 3D-DNA → Gap closing
│   ├── quality.nf            # BUSCO + Merqury + Hi-C heatmap
│   ├── annotation.nf         # RepeatModeler/Masker pipeline
│   └── genes.nf              # RNA-seq → StringTie → Gene prediction
├── conf/
│   ├── base.config           # Resource profiles
│   ├── modules.config        # Per-module parameters
│   └── test.config           # CI/CD test profile
├── bin/                      # Helper scripts (Python)
│   ├── calculate_stats.py
│   ├── plot_heatmap.py
│   └── generate_report.py
├── docs/
│   ├── usage.md
│   └── output.md
└── README.md
```

---

## 🚀 Phased Implementation Strategy

### Phase 1: Foundation (Week 1) 🎯
**Goal**: Minimal working pipeline with core assembly

**Deliverables**:
1. Repository setup with proper `.gitignore`, LICENSE
2. `main.nf` with basic workflow structure
3. `nextflow.config` with SLURM profile
4. **Core modules**:
   - `hifiasm.nf` - HiFi assembly
   - `busco.nf` - Quality check (reuse nf-core module)
5. Simple test with small dataset
6. Basic README with quickstart

**Success Criteria**:
- Pipeline runs: HiFi reads → Hifiasm assembly → BUSCO report
- Resume works (`-resume` flag)
- Resource management (CPU/memory) configured

---

### Phase 2: Hi-C Scaffolding (Week 2) 🧬
**Goal**: Add chromosome-level scaffolding

**Deliverables**:
1. **Modules**:
   - `juicer.nf` - Hi-C alignment
   - `threedna.nf` - Scaffolding
   - `lr_gapcloser.nf` - Gap filling with ONT
2. **Subworkflow**: `assembly.nf` integrating all steps
3. Quality visualization (Hi-C heatmap)
4. Extended testing

**Success Criteria**:
- Full assembly workflow: HiFi → Hi-C scaffolding → Gap closing
- Outputs match expected metrics (N50 >100Mb, QV >69)

---

### Phase 3: Annotation Pipeline (Week 3) 🧬
**Goal**: Repeat and gene annotation

**Deliverables**:
1. **Subworkflow**: `annotation.nf`
   - RepeatModeler → RepeatMasker
   - TRF (tandem repeats)
   - LTR_FINDER
2. **Subworkflow**: `genes.nf`
   - HISAT2 (reuse nf-core) → StringTie (reuse nf-core)
   - TransDecoder, GeMoMa
3. Integration scripts in `bin/`

**Success Criteria**:
- Repeat annotation: ~54% repeat content
- Gene prediction: ~24K protein-coding genes
- Proper masking for gene prediction

---

### Phase 4: Polish & Production (Week 4) ✨
**Goal**: Production-ready with documentation

**Deliverables**:
1. **Profiles**: Docker, Singularity, Conda
2. **Documentation**:
   - Comprehensive `usage.md`
   - Output descriptions
   - Troubleshooting guide
3. **Reporting**: HTML report generation
4. **CI/CD**: GitHub Actions with test profile
5. Resource benchmarking document

**Success Criteria**:
- Works on SLURM/PBS/SGE
- Container execution verified
- Documentation complete
- Test suite passes

---

## 🛠️ Engineering Best Practices

### Code Quality Standards

#### 1. Module Development
```groovy
// ✅ GOOD: Clear, documented, version-tracked
process HIFIASM {
    tag "$meta.id"
    label 'process_high'  // 64 CPUs, 500GB RAM

    conda "bioconda::hifiasm=0.19.9"
    container "quay.io/biocontainers/hifiasm:0.19.9--h2e03b76_0"

    input:
    tuple val(meta), path(hifi_reads)

    output:
    tuple val(meta), path("*.gfa"), emit: gfa
    path "versions.yml",            emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hifiasm \\
        -o ${prefix} \\
        -t ${task.cpus} \\
        ${args} \\
        ${hifi_reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(hifiasm --version 2>&1 | grep Version | cut -d' ' -f2)
    END_VERSIONS
    """
}

// ❌ BAD: Hardcoded, no versions, unclear
process hifiasm {
    script:
    """
    hifiasm -t 64 -o assembly input.fastq.gz
    """
}
```

#### 2. Configuration Management
```groovy
// conf/modules.config
process {
    withName: 'HIFIASM' {
        ext.args = '--min-ovlp 1000'
        publishDir = [
            path: { "${params.outdir}/assembly" },
            mode: params.publish_dir_mode,
            pattern: "*.gfa"
        ]
    }
}
```

#### 3. Testing Strategy
```groovy
// conf/test.config
params {
    config_profile_name = 'Test profile'
    config_profile_description = 'Minimal test dataset'
    max_cpus = 2
    max_memory = '6.GB'
    max_time = '6.h'

    // Small test inputs
    input = 'test_data/samplesheet.csv'
    genome_size = '10m'  // 10 Megabase test genome
}
```

---

### Git Workflow

#### Branch Strategy
```bash
main              # Production-ready code
├── develop       # Integration branch
├── feature/assembly      # Phase 1
├── feature/scaffolding   # Phase 2
├── feature/annotation    # Phase 3
└── feature/polish        # Phase 4
```

#### Commit Conventions
```bash
# Good commit messages
feat(assembly): add hifiasm module with container support
fix(busco): correct output channel emit name
docs(readme): add quickstart installation guide
test(ci): add GitHub Actions workflow for test profile

# Bad commit messages
update files
fix bug
changes
```

#### Development Cycle
```bash
# 1. Start feature
git checkout -b feature/assembly develop

# 2. Develop incrementally
git add modules/local/hifiasm.nf
git commit -m "feat(assembly): add hifiasm module"

# 3. Test locally
nextflow run main.nf -profile test,docker -resume

# 4. Push and create PR
git push origin feature/assembly
# Create PR to develop with clear description

# 5. After review, merge to develop
# 6. Periodic releases: develop → main (tagged)
```

---

## 🔍 Key Questions for You

Before I proceed with implementation, please clarify:

### 1. **Infrastructure**
   - What HPC scheduler? (SLURM/PBS/SGE/Local)
   - Container system preference? (Docker/Singularity/Conda)
   - Available compute resources? (Max CPUs/RAM)

### 2. **Scope Priorities**
   - Start with Phase 1 only (basic assembly)?
   - Or implement specific phase immediately?
   - Any modules we can skip for MVP?

### 3. **Data Availability**
   - Do you have test data ready?
   - Or should I create mock data generators for testing?

### 4. **Collaboration**
   - Solo project or team repository?
   - GitHub organization or personal repo?
   - Code review process preference?

### 5. **Tool Preferences**
   - Any specific tool versions you need?
   - Existing databases/references locations?
   - Storage paths conventions (e.g., `/scratch`, `/project`)?

---

## 📝 Next Immediate Steps

Once you answer the questions above, I'll:

1. **Initialize Git repository** with proper structure
2. **Set up base configuration** for your infrastructure
3. **Implement Phase 1** (core assembly pipeline)
4. **Create test profile** with validation

**Estimated time to Phase 1 completion**: 1-2 days with your input

---

## 📚 Resources & References

### Documentation
- [nf-core guidelines](https://nf-co.re/docs/guidelines)
- [Nextflow patterns](https://nextflow-io.github.io/patterns/)
- [BioContainers registry](https://biocontainers.pro/)

### Tools
- [nf-core tools](https://nf-co.re/tools): `nf-core modules list`, `nf-core modules install`
- [Nextflow Tower](https://tower.nf/): Workflow monitoring (optional)

### Community
- [nf-core Slack](https://nf-co.re/join/slack): Active support community
- [Nextflow Gitter](https://gitter.im/nextflow-io/nextflow): Technical discussions

---

**Ready to start building?** Let me know your answers to the questions above, and we'll begin with a solid foundation! 🚀
