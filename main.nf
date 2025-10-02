#!/usr/bin/env nextflow
/*
========================================================================================
    T2T Genome Assembly Pipeline - Phase 1
========================================================================================
    Github : https://github.com/alarawms/t2t-sh
    Author : KAUST Bioinformatics
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

include { HIFIASM       } from './modules/local/hifiasm'
include { GFA_TO_FASTA  } from './modules/local/gfa_to_fasta'
include { BUSCO         } from './modules/local/busco'

/*
========================================================================================
    NAMED WORKFLOW
========================================================================================
*/

workflow T2T_ASSEMBLY {

    take:
    ch_input  // channel: [ val(meta), path(hifi_reads) ]

    main:
    ch_versions = Channel.empty()

    //
    // MODULE: Run Hifiasm assembly
    //
    HIFIASM(ch_input)
    ch_versions = ch_versions.mix(HIFIASM.out.versions)

    //
    // MODULE: Convert GFA to FASTA for BUSCO
    //
    GFA_TO_FASTA(HIFIASM.out.primary_contigs)
    ch_versions = ch_versions.mix(GFA_TO_FASTA.out.versions)

    //
    // MODULE: Run BUSCO quality assessment
    //
    if (params.busco_lineage) {
        BUSCO(
            GFA_TO_FASTA.out.fasta,
            params.busco_lineage,
            params.busco_mode
        )
        ch_versions = ch_versions.mix(BUSCO.out.versions)
    }

    emit:
    assembly_gfa   = HIFIASM.out.gfa
    assembly_fasta = GFA_TO_FASTA.out.fasta
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
    // SUBWORKFLOW: Parse input samplesheet
    //
    ch_input = Channel
        .fromPath(params.input)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            def meta = [:]
            meta.id = row.sample_id

            def reads = file(row.hifi_reads)
            if (!reads.exists()) {
                exit 1, "ERROR: HiFi reads file does not exist: ${row.hifi_reads}"
            }

            return [ meta, reads ]
        }

    //
    // WORKFLOW: Run Phase 1 assembly pipeline
    //
    T2T_ASSEMBLY(ch_input)
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
