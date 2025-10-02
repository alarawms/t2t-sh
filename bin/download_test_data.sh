#!/usr/bin/env bash
#
# Download test data for T2T assembly pipeline
# Multiple options available depending on size and complexity needs
#

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_DATA_DIR="${SCRIPT_DIR}/../test_data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create test data directory
mkdir -p "${TEST_DATA_DIR}"

#==============================================
# Option 1: Tiny test dataset from Hifiasm
#==============================================
download_hifiasm_test() {
    print_header "Downloading Hifiasm Test Data (2Mb, fastest)"

    cd "${TEST_DATA_DIR}"

    print_info "Downloading chr11-2M.fa.gz (2 Megabase subset)..."
    wget -q --show-progress https://github.com/chhylp123/hifiasm/releases/download/v0.7/chr11-2M.fa.gz

    # Convert to FASTQ format for pipeline compatibility
    print_info "Converting to FASTQ format..."
    gunzip -c chr11-2M.fa.gz | awk '
        /^>/ {
            if (seq != "") {
                qual = ""
                for (i = 1; i <= length(seq); i++) qual = qual "I"
                print "@" substr(name, 2)
                print seq
                print "+"
                print qual
            }
            name = $0
            seq = ""
            next
        }
        { seq = seq $0 }
        END {
            if (seq != "") {
                qual = ""
                for (i = 1; i <= length(seq); i++) qual = qual "I"
                print "@" substr(name, 2)
                print seq
                print "+"
                print qual
            }
        }
    ' | gzip > test_hifi_tiny.fastq.gz

    # Update samplesheet
    echo "sample_id,hifi_reads" > samplesheet_test.csv
    echo "test_tiny,${TEST_DATA_DIR}/test_hifi_tiny.fastq.gz" >> samplesheet_test.csv

    print_success "Downloaded tiny test data (2Mb)"
    print_info "Samplesheet: ${TEST_DATA_DIR}/samplesheet_test.csv"
    print_info "Reads: ${TEST_DATA_DIR}/test_hifi_tiny.fastq.gz"
}

#==============================================
# Option 2: E. coli from SRA (requires SRA toolkit)
#==============================================
download_ecoli_sra() {
    print_header "Downloading E. coli K12 HiFi from SRA (~500Mb)"

    if ! command_exists fasterq-dump; then
        print_error "SRA Toolkit not found!"
        print_info "Install with: conda install -c bioconda sra-tools"
        print_info "Or download from: https://github.com/ncbi/sra-tools/wiki/Downloads"
        return 1
    fi

    cd "${TEST_DATA_DIR}"

    print_info "Downloading SRR10971019 (E. coli K12 PacBio HiFi)..."
    print_info "This will take 5-10 minutes depending on connection..."

    # Download and convert to FASTQ
    fasterq-dump SRR10971019 --progress --threads 4

    # Compress
    print_info "Compressing FASTQ file..."
    gzip SRR10971019.fastq

    # Subsample to ~50Mb for faster testing (optional)
    print_info "Creating subsampled version (50x coverage ~50Mb)..."
    gunzip -c SRR10971019.fastq.gz | head -n 200000 | gzip > test_ecoli_50x.fastq.gz

    # Update samplesheet
    echo "sample_id,hifi_reads" > samplesheet_test_ecoli.csv
    echo "ecoli_k12,${TEST_DATA_DIR}/test_ecoli_50x.fastq.gz" >> samplesheet_test_ecoli.csv

    print_success "Downloaded E. coli test data"
    print_info "Full dataset: ${TEST_DATA_DIR}/SRR10971019.fastq.gz"
    print_info "Subsampled (50x): ${TEST_DATA_DIR}/test_ecoli_50x.fastq.gz"
    print_info "Samplesheet: ${TEST_DATA_DIR}/samplesheet_test_ecoli.csv"
}

#==============================================
# Option 3: Simulated HiFi reads (requires pbsim3)
#==============================================
generate_simulated_data() {
    print_header "Generating Simulated HiFi Reads"

    if ! command_exists pbsim3; then
        print_error "pbsim3 not found!"
        print_info "Install with: conda install -c bioconda pbsim3"
        return 1
    fi

    cd "${TEST_DATA_DIR}"

    # Download a small reference genome (e.g., E. coli)
    print_info "Downloading E. coli K12 reference genome..."
    wget -q --show-progress https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
    gunzip GCF_000005845.2_ASM584v2_genomic.fna.gz

    print_info "Simulating HiFi reads with pbsim3..."
    pbsim3 \
        --strategy wgs \
        --method qshmm \
        --qshmm data/QSHMM-RSII.model \
        --depth 30 \
        --genome GCF_000005845.2_ASM584v2_genomic.fna \
        --prefix simulated

    # Concatenate and compress
    cat simulated*.fastq | gzip > test_simulated.fastq.gz
    rm simulated*.fastq simulated*.ref simulated*.maf

    # Update samplesheet
    echo "sample_id,hifi_reads" > samplesheet_test_simulated.csv
    echo "ecoli_simulated,${TEST_DATA_DIR}/test_simulated.fastq.gz" >> samplesheet_test_simulated.csv

    print_success "Generated simulated test data"
    print_info "Samplesheet: ${TEST_DATA_DIR}/samplesheet_test_simulated.csv"
}

#==============================================
# Option 4: Download from PacBio datasets
#==============================================
download_pacbio_dataset() {
    print_header "Downloading PacBio Public Dataset"

    cd "${TEST_DATA_DIR}"

    print_info "Available PacBio datasets:"
    echo "1. Human HG002 (large, ~30GB)"
    echo "2. Drosophila (medium, ~5GB)"
    echo "3. Yeast (small, ~500MB)"

    print_info "Visit https://www.pacb.com/connect/datasets/ for more options"
    print_info "This script currently downloads the Yeast dataset..."

    # Example: Download yeast dataset (adjust URL as needed)
    print_error "Direct download URLs need to be obtained from PacBio website"
    print_info "Please visit: https://www.pacb.com/connect/datasets/"
}

#==============================================
# Main menu
#==============================================
show_usage() {
    cat <<EOF
Usage: $0 [option]

Options:
  1, tiny       Download tiny test data from Hifiasm (2Mb, ~1 min)
  2, ecoli      Download E. coli from SRA (500Mb, ~10 min, requires SRA toolkit)
  3, simulate   Generate simulated reads (requires pbsim3)
  4, pacbio     Info on PacBio public datasets
  all           Download all available datasets
  -h, --help    Show this help message

Examples:
  $0 tiny       # Quick test with minimal data
  $0 ecoli      # Real E. coli HiFi reads
  $0 all        # Download everything

Requirements:
  - wget (for downloading)
  - gzip (for compression)
  - sra-tools (for option 2)
  - pbsim3 (for option 3)

EOF
}

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    case "$1" in
        1|tiny)
            download_hifiasm_test
            ;;
        2|ecoli)
            download_ecoli_sra
            ;;
        3|simulate)
            generate_simulated_data
            ;;
        4|pacbio)
            download_pacbio_dataset
            ;;
        all)
            print_header "Downloading All Test Datasets"
            download_hifiasm_test
            echo ""
            download_ecoli_sra || true
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_success "Done! Test data ready in: ${TEST_DATA_DIR}"
    print_info "Next steps:"
    echo "  1. Test pipeline: nextflow run main.nf -profile test,docker"
    echo "  2. Or use downloaded data: nextflow run main.nf -profile docker --input ${TEST_DATA_DIR}/samplesheet_*.csv"
}

main "$@"
