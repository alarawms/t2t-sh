# Test Data Summary

Quick reference for available test datasets.

## 🎯 Quick Commands

```bash
# Option 1: Fastest - Tiny test (2Mb, ~1 min)
./bin/download_test_data.sh tiny
nextflow run main.nf -profile test,docker

# Option 2: Real Data - E. coli (500Mb, ~10 min)
conda install -c bioconda sra-tools  # First time only
./bin/download_test_data.sh ecoli
nextflow run main.nf -profile docker --input test_data/samplesheet_test_ecoli.csv --genome_size 4.6m --busco_lineage bacteria_odb10

# Option 3: All datasets
./bin/download_test_data.sh all
```

## 📊 Dataset Comparison

| Dataset | Size | Download Time | Assembly Time | BUSCO Valid | Best For |
|---------|------|---------------|---------------|-------------|----------|
| **Tiny** | 2 Mb | 1 min | 2-5 min | ❌ | Quick validation, CI/CD |
| **E. coli (sub)** | 50 Mb | 5 min | 20-30 min | ✅ | Development testing |
| **E. coli (full)** | 500 Mb | 10 min | 30-60 min | ✅ | Full validation |
| **Simulated** | Custom | 5-10 min | Varies | ✅ | Controlled testing |

## 🔗 Direct Download Links

### Tiny Test Data (Hifiasm)
- **URL**: https://github.com/chhylp123/hifiasm/releases/download/v0.7/chr11-2M.fa.gz
- **Size**: ~5 MB
- **Description**: 2 Mb subset from human chromosome 11
- **Use**: Quick pipeline validation

### E. coli K12 HiFi (SRA)
- **Accession**: SRR10971019
- **Genome**: E. coli K12 MG1655
- **Coverage**: ~150x
- **Size**: ~500 MB
- **Paper**: "WGS of E. coli K12 with PacBio HiFi reads for genome assembly"
- **Use**: Realistic assembly testing

### Alternative SRA Datasets

**E. coli E2348/69**:
- From: "Comparison of long-read sequencing technologies"
- Blog: https://rrwick.github.io/2023/03/07/pacbio-hifi.html
- Multiple tech comparison (Illumina + ONT + HiFi)

## 📖 Recommended Test Workflow

### Step 1: Installation Validation (5 minutes)
```bash
./bin/download_test_data.sh tiny
nextflow run main.nf -profile test,docker
```
**Expected**: Pipeline completes without errors

### Step 2: Full Pipeline Test (1 hour)
```bash
./bin/download_test_data.sh ecoli
nextflow run main.nf -profile docker \
  --input test_data/samplesheet_test_ecoli.csv \
  --outdir results_ecoli \
  --genome_size 4.6m \
  --busco_lineage bacteria_odb10
```
**Expected**:
- Assembly size: ~4.6 Mb
- BUSCO completeness: >95%
- N50: >4 Mb (closed circular genome)

### Step 3: HPC Testing (KAUST Ibex)
```bash
# Transfer test data to Ibex
scp -r test_data/ ibex:/ibex/scratch/$USER/

# Run on Ibex
nextflow run main.nf -profile kaust \
  --input /ibex/scratch/$USER/test_data/samplesheet_test_ecoli.csv \
  --outdir /ibex/scratch/$USER/results_test \
  --genome_size 4.6m \
  --busco_lineage bacteria_odb10
```

## 🌐 Additional Public Resources

### PacBio Official Datasets
**URL**: https://www.pacb.com/connect/datasets/

Available organisms:
- **Human HG002**: ~30 GB, 3.2 Gb genome (GIAB reference)
- **Drosophila melanogaster**: ~5 GB, 140 Mb genome
- **Saccharomyces cerevisiae**: ~500 MB, 12 Mb genome
- **Arabidopsis thaliana**: ~2 GB, 120 Mb genome

### SRA Search Tips

**Find HiFi datasets**:
```
Search on NCBI SRA:
"pacbio hifi"[All Fields] AND "genome assembly"[All Fields]

Filter by:
- Library Strategy: WGS
- Platform: PACBIO_SMRT
- Access: Public
```

**Example queries**:
- Bacterial: `"escherichia coli"[organism] AND "pacbio"[platform] AND "hifi"[All Fields]`
- Plant: `"arabidopsis thaliana"[organism] AND "pacbio"[platform]`
- Mammal: `"mus musculus"[organism] AND "hifi"[All Fields]`

### Genome Ark
**URL**: https://www.genomeark.org/

High-quality reference genomes from Vertebrate Genomes Project (VGP) and other initiatives. Many include:
- PacBio HiFi reads
- Hi-C data
- Reference-quality assemblies

## 🛠️ Manual Download Examples

### Download from SRA
```bash
# Install SRA toolkit
conda install -c bioconda sra-tools

# Configure (first time)
vdb-config --interactive

# Download
fasterq-dump SRR10971019 --threads 4
gzip SRR10971019.fastq

# Create samplesheet
echo "sample_id,hifi_reads" > samplesheet.csv
echo "ecoli,$(pwd)/SRR10971019.fastq.gz" >> samplesheet.csv
```

### Download from ENA (faster alternative)
```bash
# Often faster than SRA
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR109/019/SRR10971019/SRR10971019.fastq.gz
```

### Download from PacBio
```bash
# Example: HG002 chromosome 20
wget https://downloads.pacbcloud.com/public/dataset/2021-11-Sequel2e-CCS/m64011_181218_235052.Q20.fastq.gz

# Note: Check PacBio datasets page for current URLs
```

## 📝 Creating Custom Test Data

### Subsample Large Dataset
```bash
# Take first 50,000 reads (~50x for E. coli)
gunzip -c large_dataset.fastq.gz | head -n 200000 | gzip > subsampled.fastq.gz
```

### Simulate with pbsim3
```bash
conda install -c bioconda pbsim3

# Download reference
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
gunzip *.fna.gz

# Simulate HiFi reads
pbsim3 \
  --strategy wgs \
  --method qshmm \
  --qshmm /path/to/QSHMM-RSII.model \
  --depth 30 \
  --genome reference.fna \
  --prefix simulated
```

## ✅ Validation Checklist

After downloading test data:

- [ ] Files downloaded successfully
- [ ] Files are readable and not corrupted
- [ ] Samplesheet created with correct paths
- [ ] FASTQ format validated (optional: `seqkit stats`)
- [ ] Pipeline test runs without errors
- [ ] Output files generated in expected locations
- [ ] BUSCO results reasonable (if applicable)

## 📚 Citations

If you use these datasets, please cite:

**E. coli SRR10971019**:
```
De Maio et al. (2019)
"Comparison of long-read sequencing technologies in interrogating bacteria and fly genomes"
```

**Hifiasm**:
```
Cheng, H., Concepcion, G.T., Feng, X. et al. (2021)
Haplotype-resolved de novo assembly using phased assembly graphs with hifiasm.
Nat Methods 18, 170–175. https://doi.org/10.1038/s41592-020-01056-5
```

**PacBio Datasets**:
- Check individual dataset pages for citation information

## 🆘 Support

Issues with test data?

1. Check [docs/test_data.md](docs/test_data.md) for detailed guide
2. Verify disk space: `df -h test_data/`
3. Check network connection
4. Try alternative download method (SRA vs ENA)
5. Open issue: https://github.com/alarawms/t2t-sh/issues

---

**Last Updated**: October 2025
**Maintained By**: KAUST Bioinformatics Team
