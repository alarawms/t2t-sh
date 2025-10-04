#!/bin/bash
#SBATCH --job-name=t2t-resume
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --partition=batch
#SBATCH --output=logs/t2t_resume_%j.out
#SBATCH --error=logs/t2t_resume_%j.err

# T2T Genome Assembly Pipeline - Resume Script
# Usage: sbatch resume_ibex.sh

# Exit on error
set -e

# Create logs directory
mkdir -p logs

# Load required modules
module purge
module load nextflow
module load singularity

# Print configuration
echo "================================"
echo "T2T Assembly Pipeline - RESUME"
echo "================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Resume time: $(date)"
echo "================================"
echo ""

# Run Nextflow pipeline with resume
nextflow run main.nf \
    -profile kaust \
    -resume

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo "================================"
    echo "Pipeline resumed and completed!"
    echo "End time: $(date)"
    echo "================================"
else
    echo ""
    echo "================================"
    echo "Pipeline failed after resume!"
    echo "Check logs: logs/t2t_resume_${SLURM_JOB_ID}.err"
    echo "================================"
    exit 1
fi
