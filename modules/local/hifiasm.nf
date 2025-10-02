/*
 * Hifiasm - HiFi genome assembly
 * https://github.com/chhylp123/hifiasm
 */

process HIFIASM {
    tag "$meta.id"
    label 'process_very_high'

    conda "bioconda::hifiasm=0.25.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.25.0--h5ca1c30_0' :
        'quay.io/biocontainers/hifiasm:0.25.0--h5ca1c30_0' }"

    input:
    tuple val(meta), path(hifi_reads)

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
    """
    hifiasm \\
        -o ${prefix} \\
        -t ${task.cpus} \\
        ${bloom_flag} \\
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
