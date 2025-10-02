/*
 * BUSCO - Benchmarking Universal Single-Copy Orthologs
 * https://busco.ezlab.org/
 */

process BUSCO {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::busco=5.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.8.3--pyhdfd78af_1' :
        'quay.io/biocontainers/busco:5.8.3--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(assembly)
    val lineage
    val mode

    output:
    tuple val(meta), path("*-busco/"), emit: busco_dir
    tuple val(meta), path("*-busco/short_summary.*.txt"), emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Create output directory
    mkdir -p ${prefix}-busco

    # Run BUSCO
    busco \\
        --in ${assembly} \\
        --out ${prefix}-busco \\
        --lineage_dataset ${lineage} \\
        --mode ${mode} \\
        --cpu ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$(busco --version 2>&1 | sed 's/BUSCO //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}-busco
    touch ${prefix}-busco/short_summary.specific.${lineage}.${prefix}-busco.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$(busco --version 2>&1 | sed 's/BUSCO //')
    END_VERSIONS
    """
}
