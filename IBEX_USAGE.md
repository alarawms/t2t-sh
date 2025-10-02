# Running on KAUST Ibex

Quick guide for submitting T2T assembly jobs to KAUST Ibex.

## Quick Start

```bash
# 1. Prepare your samplesheet
cp samplesheet_examples/complete_t2t.csv my_sample.csv
# Edit with your data paths

# 2. Submit to SLURM
sbatch submit_ibex.sh my_sample.csv results

# 3. Monitor job
squeue -u $USER
```

## Submission Script

The `submit_ibex.sh` script handles:
- SLURM job submission with largemem partition
- Module loading (Nextflow + Singularity)
- Nextflow execution with `-resume` support
- Log file management

### Default Resources

- **Partition**: `largemem`
- **CPUs**: 32
- **Memory**: 500 GB
- **Time**: 72 hours
- **Logs**: `logs/t2t_<jobid>.out/err`

### Customizing Resources

Edit the `#SBATCH` directives in `submit_ibex.sh`:

```bash
#SBATCH --cpus-per-task=64      # More CPUs
#SBATCH --mem=1000G             # More memory
#SBATCH --time=168:00:00        # 7 days
```

## Usage Examples

### HiFi-only assembly
```bash
sbatch submit_ibex.sh samplesheet_examples/hifi_only.csv results_hifi
```

### Complete T2T assembly
```bash
sbatch submit_ibex.sh samplesheet_examples/complete_t2t.csv results_t2t
```

### Multiple samples
```bash
sbatch submit_ibex.sh samplesheet_examples/multi_sample.csv results_batch
```

## Monitoring Jobs

### Check job status
```bash
squeue -u $USER
```

### View live output
```bash
tail -f logs/t2t_<jobid>.out
```

### Check for errors
```bash
tail -f logs/t2t_<jobid>.err
```

## Resuming Failed Jobs

Nextflow automatically resumes from the last successful step:

```bash
# Just resubmit - it will continue where it stopped
sbatch submit_ibex.sh my_sample.csv results
```

## Canceling Jobs

```bash
scancel <jobid>
```

## Storage Locations

- **Input data**: `/ibex/user/$USER/data/`
- **Results**: Specify with second argument to `submit_ibex.sh`
- **Work directory**: `work/` (in project directory)
- **Singularity cache**: `work/singularity_cache/` (automatically created in work directory)

## Troubleshooting

### Job fails to start
```bash
# Check queue availability
sinfo -p largemem

# Check your quota
quota
```

### Out of memory error
```bash
# Increase memory in submit_ibex.sh
#SBATCH --mem=1000G
```

### Job timeout
```bash
# Increase time limit
#SBATCH --time=168:00:00
```

### Module not found
```bash
# Load modules manually first
module load nextflow/25.04.5
module load singularity
```

## Email Notifications

Edit your email in `submit_ibex.sh`:
```bash
#SBATCH --mail-user=your.email@kaust.edu.sa
```

Notification types:
- `BEGIN` - Job starts
- `END` - Job completes
- `FAIL` - Job fails
- `ALL` - All events

## Best Practices

1. **Test first**: Use small test data before full runs
2. **Check paths**: Ensure all data paths in samplesheet are accessible from Ibex
3. **Use absolute paths**: Avoid relative paths in samplesheets
4. **Monitor resources**: Check `logs/` for resource usage
5. **Clean up**: Remove old work directories after successful runs

## Support

- **Ibex documentation**: https://docs.hpc.kaust.edu.sa
- **Issues**: https://github.com/alarawms/t2t-sh/issues
- **HPC support**: hpc-support@kaust.edu.sa
