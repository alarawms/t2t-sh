/*
 * BUSCO - Benchmarking Universal Single-Copy Orthologs
 * https://busco.ezlab.org/
 */

process BUSCO {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/busco", mode: params.publish_dir_mode

    conda "bioconda::busco=5.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.8.3--pyhdfd78af_1' :
        'quay.io/biocontainers/busco:5.8.3--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(assembly)
    val lineage
    val mode

    output:
    tuple val(meta), path("*-busco"), emit: busco_dir
    tuple val(meta), path("*-busco/short_summary.*.txt"), emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Run BUSCO (it creates its own output directory)
    busco -f \\
        --in ${assembly} \\
        --out ${prefix}-busco \\
        --lineage_dataset ${lineage} \\
        --mode ${mode} \\
        --cpu ${task.cpus} \\
        ${args}

    # Ensure output directory exists for Nextflow
    if [ ! -d "${prefix}-busco" ]; then
        echo "ERROR: BUSCO did not create expected output directory"
        exit 1
    fi

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
