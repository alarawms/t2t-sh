#!/usr/bin/env nextflow
/*
========================================================================================
    T2T Genome Assembly Pipeline
========================================================================================
    Github : https://github.com/alarawms/t2t-sh
    Author : KAUST Bioinformatics

    Supports multiple input types:
    - HiFi reads (required) - PacBio HiFi long reads
    - ONT reads (optional) - Oxford Nanopore for gap closing
    - Hi-C reads (optional) - Chromosome scaffolding
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { INPUT_CHECK   } from './subworkflows/local/input_check'
include { HIFIASM       } from './modules/local/hifiasm'
include { GFA_TO_FASTA  } from './modules/local/gfa_to_fasta'
include { BUSCO         } from './modules/local/busco'
include { JUICER        } from './modules/local/juicer'
include { THREEDNA      } from './modules/local/threedna'
include { TGSGAPCLOSER  } from './modules/local/tgsgapcloser'

/*
========================================================================================
    NAMED WORKFLOW
========================================================================================
*/

workflow T2T_ASSEMBLY {

    take:
    ch_hifi  // channel: [ val(meta), path(hifi_reads) ]
    ch_ont   // channel: [ val(meta), path(ont_reads) ]
    ch_hic   // channel: [ val(meta), [path(hic_r1), path(hic_r2)] ]

    main:
    ch_versions = Channel.empty()

    //
    // Combine all read types for Hifiasm
    // Join HiFi with ONT and Hi-C by sample meta.id
    //
    ch_hifi
        .join(ch_ont, remainder: true)
        .join(ch_hic, remainder: true)
        .map { meta, hifi, ont, hic ->
            // Provide default empty values for missing reads
            def ont_reads = ont ?: file('NO_ONT_FILE')
            def hic_reads = hic ?: file('NO_HIC_FILE')
            [meta, hifi, ont_reads, hic_reads]
        }
        .set { ch_all_reads }

    //
    // MODULE: Run Hifiasm assembly with all available read types
    //
    HIFIASM(ch_all_reads)
    ch_versions = ch_versions.mix(HIFIASM.out.versions)

    //
    // MODULE: Convert GFA to FASTA for BUSCO
    //
    GFA_TO_FASTA(HIFIASM.out.primary_contigs)
    ch_versions = ch_versions.mix(GFA_TO_FASTA.out.versions)

    //
    // MODULE: Run BUSCO quality assessment on initial assembly
    //
    if (params.busco_lineage) {
        BUSCO(
            GFA_TO_FASTA.out.fasta,
            params.busco_lineage,
            params.busco_mode
        )
        ch_versions = ch_versions.mix(BUSCO.out.versions)
    }

    //
    // Phase 3: Hi-C Scaffolding (when Hi-C reads available)
    //
    ch_scaffolded = Channel.empty()

    ch_hic
        .join(GFA_TO_FASTA.out.fasta)
        .map { meta, hic, fasta ->
            [meta, fasta, hic[0], hic[1]]  // meta, assembly, hic_r1, hic_r2
        }
        .set { ch_juicer_input }

    if (ch_juicer_input) {
        //
        // MODULE: Juicer - Hi-C read alignment
        //
        JUICER(ch_juicer_input)
        ch_versions = ch_versions.mix(JUICER.out.versions)

        //
        // MODULE: 3D-DNA - Chromosome scaffolding
        //
        JUICER.out.merged_nodups
            .join(GFA_TO_FASTA.out.fasta)
            .map { meta, nodups, fasta ->
                [meta, fasta, nodups]
            }
            .set { ch_threedna_input }

        THREEDNA(ch_threedna_input)
        ch_versions = ch_versions.mix(THREEDNA.out.versions)
        ch_scaffolded = THREEDNA.out.scaffolds
    } else {
        ch_scaffolded = GFA_TO_FASTA.out.fasta
    }

    //
    // Phase 3: ONT Gap Closing (when ONT reads available)
    //
    ch_final_assembly = Channel.empty()

    ch_ont
        .join(ch_scaffolded)
        .map { meta, ont, scaffolds ->
            [meta, scaffolds, ont]
        }
        .set { ch_gapcloser_input }

    if (ch_gapcloser_input) {
        //
        // MODULE: TGS-GapCloser - Fill gaps with ONT reads
        //
        TGSGAPCLOSER(ch_gapcloser_input)
        ch_versions = ch_versions.mix(TGSGAPCLOSER.out.versions)
        ch_final_assembly = TGSGAPCLOSER.out.assembly
    } else {
        ch_final_assembly = ch_scaffolded
    }

    emit:
    assembly_gfa   = HIFIASM.out.gfa
    assembly_fasta = GFA_TO_FASTA.out.fasta
    scaffolds      = ch_scaffolded
    final_assembly = ch_final_assembly
    busco_summary  = params.busco_lineage ? BUSCO.out.summary : Channel.empty()
    versions       = ch_versions
}

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow {

    //
    // SUBWORKFLOW: Check input samplesheet and parse reads
    //
    INPUT_CHECK(params.input)

    //
    // INFO: Log data availability
    //
    INPUT_CHECK.out.hifi
        .count()
        .subscribe { count ->
            log.info "Found ${count} sample(s) with HiFi reads"
        }

    INPUT_CHECK.out.ont
        .count()
        .subscribe { count ->
            if (count > 0) {
                log.info "Found ${count} sample(s) with ONT reads (Phase 2 feature)"
            }
        }

    INPUT_CHECK.out.hic
        .count()
        .subscribe { count ->
            if (count > 0) {
                log.info "Found ${count} sample(s) with Hi-C reads (Phase 2 feature)"
            }
        }

    //
    // WORKFLOW: Run Phase 1 assembly pipeline
    //
    T2T_ASSEMBLY(
        INPUT_CHECK.out.hifi,
        INPUT_CHECK.out.ont,
        INPUT_CHECK.out.hic
    )
}

/*
========================================================================================
    WORKFLOW COMPLETION
========================================================================================
*/

workflow.onComplete {
    log.info ""
    log.info "Pipeline execution summary"
    log.info "=========================="
    log.info "Completed at : ${workflow.complete}"
    log.info "Duration     : ${workflow.duration}"
    log.info "Success      : ${workflow.success}"
    log.info "Work Dir     : ${workflow.workDir}"
    log.info "Exit status  : ${workflow.exitStatus}"
    log.info ""

    if (workflow.success) {
        log.info "Results saved to: ${params.outdir}"
    }
}

workflow.onError {
    log.error "Pipeline execution failed"
    log.error "Error message: ${workflow.errorMessage}"
    log.error "Error report: ${workflow.errorReport}"
}

/*
========================================================================================
    THE END
========================================================================================
*/
