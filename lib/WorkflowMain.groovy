/*
 * Workflow initialization and parameter validation
 */

class WorkflowMain {

    //
    // Print help message
    //
    public static void helpMessage(workflow, params, log) {
        log.info """
        ================================================================
        T2T Genome Assembly Pipeline v${workflow.manifest.version}
        ================================================================

        Usage:
          nextflow run main.nf --input reads.csv --outdir results [options]

        Required Arguments:
          --input         Path to input CSV with sample information
          --outdir        Output directory for results

        Assembly Options:
          --genome_size   Expected genome size (e.g., '3.2g')
          --hifiasm_args  Additional hifiasm arguments

        Quality Control:
          --busco_lineage BUSCO lineage dataset (e.g., 'eukaryota_odb10')
          --busco_mode    BUSCO mode (genome, transcriptome, proteins)

        Profiles:
          -profile kaust          Run on KAUST Ibex with SLURM
          -profile docker         Run locally with Docker
          -profile conda          Run locally with Conda
          -profile singularity    Run locally with Singularity
          -profile test           Run with test data

        Examples:
          # Run on KAUST Ibex
          nextflow run main.nf -profile kaust --input samples.csv --outdir results

          # Run locally with Docker
          nextflow run main.nf -profile docker --input samples.csv --outdir results

          # Run test
          nextflow run main.nf -profile test,docker

        ================================================================
        """.stripIndent()
    }

    //
    // Validate parameters
    //
    public static void validateParams(params, log) {
        if (!params.input) {
            log.error "ERROR: --input is required!"
            System.exit(1)
        }

        def input_file = new File(params.input)
        if (!input_file.exists()) {
            log.error "ERROR: Input file does not exist: ${params.input}"
            System.exit(1)
        }
    }

    //
    // Initialize workflow
    //
    public static void initialise(workflow, params, log) {
        // Print help message if requested
        if (params.help) {
            helpMessage(workflow, params, log)
            System.exit(0)
        }

        // Validate parameters (skip for test profile)
        if (!params.test) {
            validateParams(params, log)
        }

        // Print parameter summary
        log.info """
        ================================================================
        T2T Genome Assembly Pipeline v${workflow.manifest.version}
        ================================================================
        Input         : ${params.input}
        Output        : ${params.outdir}
        Genome size   : ${params.genome_size ?: 'Not specified'}
        BUSCO lineage : ${params.busco_lineage ?: 'Not specified'}
        Profile       : ${workflow.profile}
        ================================================================
        """.stripIndent()
    }
}
