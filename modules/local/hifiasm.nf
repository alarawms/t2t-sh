/*
 * Hifiasm - HiFi genome assembly
 * https://github.com/chhylp123/hifiasm
 */

process HIFIASM {
    tag "$meta.id"
    label 'process_very_high'
    publishDir "${params.outdir}/assembly", mode: params.publish_dir_mode

    conda "bioconda::hifiasm=0.25.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.25.0--h5ca1c30_0' :
        'quay.io/biocontainers/hifiasm:0.25.0--h5ca1c30_0' }"

    input:
    tuple val(meta), path(hifi_reads), path(ont_reads), path(hic_reads)

    output:
    tuple val(meta), path("*.gfa"),         emit: gfa
    tuple val(meta), path("*.p_ctg.gfa"),   emit: primary_contigs,   optional: true
    tuple val(meta), path("*.a_ctg.gfa"),   emit: alternate_contigs, optional: true
    tuple val(meta), path("*.bp.p_ctg.*"),  emit: haplotype1,        optional: true
    tuple val(meta), path("*.bp.hap1.*"),   emit: haplotype1_alt,    optional: true
    tuple val(meta), path("*.bp.hap2.*"),   emit: haplotype2,        optional: true
    path "versions.yml",                    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Use -f0 for small test datasets to disable bloom filter (saves memory)
    def bloom_flag = task.memory.toGiga() < 20 ? '-f0' : ''

    // ONT ultra-long read integration
    def ont_flag = ont_reads && ont_reads.name != 'NO_ONT_FILE' ? "--ul ${ont_reads}" : ''

    // Hi-C read integration for phasing (expects paired-end reads)
    def hic_flag = ''
    if (hic_reads && hic_reads.name != 'NO_HIC_FILE') {
        // hic_reads should be a list [R1, R2]
        if (hic_reads instanceof List && hic_reads.size() >= 2) {
            hic_flag = "--h1 ${hic_reads[0]} --h2 ${hic_reads[1]}"
        } else if (hic_reads instanceof List && hic_reads.size() == 1) {
            // Single file provided - skip Hi-C
            hic_flag = ''
        }
    }

    """
    hifiasm \\
        -o ${prefix} \\
        -t ${task.cpus} \\
        ${bloom_flag} \\
        ${ont_flag} \\
        ${hic_flag} \\
        ${args} \\
        ${hifi_reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(hifiasm --version 2>&1 | grep Version | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.gfa
    touch ${prefix}.p_ctg.gfa
    touch ${prefix}.a_ctg.gfa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(hifiasm --version 2>&1 | grep Version | cut -d' ' -f2)
    END_VERSIONS
    """
}
