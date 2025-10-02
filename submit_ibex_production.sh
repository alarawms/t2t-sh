#!/bin/bash
#SBATCH --job-name=t2t-assembly
#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=500G
#SBATCH --partition=largemem
#SBATCH --output=logs/t2t_%j.out
#SBATCH --error=logs/t2t_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=$USER@kaust.edu.sa

# T2T Genome Assembly Pipeline - KAUST Ibex Submission Script (PRODUCTION)
# High-resource configuration for large genomes
# Usage: sbatch submit_ibex_production.sh <samplesheet.csv> <output_dir>

# Exit on error
set -e

# Create logs directory
mkdir -p logs

# Load required modules
module purge
module load nextflow/25.04.5
module load singularity

# Input validation
if [ $# -lt 2 ]; then
    echo "Usage: sbatch submit_ibex.sh <samplesheet.csv> <output_dir>"
    echo "Example: sbatch submit_ibex.sh samplesheet_examples/complete_t2t.csv results"
    exit 1
fi

SAMPLESHEET=$1
OUTDIR=$2

# Check if samplesheet exists
if [ ! -f "$SAMPLESHEET" ]; then
    echo "Error: Samplesheet not found: $SAMPLESHEET"
    exit 1
fi

# Print configuration
echo "================================"
echo "T2T Assembly Pipeline - IBEX"
echo "================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Samplesheet: $SAMPLESHEET"
echo "Output: $OUTDIR"
echo "Start time: $(date)"
echo "================================"
echo ""

# Run Nextflow pipeline
nextflow run main.nf \
    -profile kaust \
    --input "$SAMPLESHEET" \
    --outdir "$OUTDIR" \
    --max_cpus 32 \
    --max_memory 500.GB \
    --max_time 72.h \
    -resume

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo "================================"
    echo "Pipeline completed successfully!"
    echo "End time: $(date)"
    echo "Results: $OUTDIR"
    echo "================================"
else
    echo ""
    echo "================================"
    echo "Pipeline failed!"
    echo "Check logs: logs/t2t_${SLURM_JOB_ID}.err"
    echo "================================"
    exit 1
fi
