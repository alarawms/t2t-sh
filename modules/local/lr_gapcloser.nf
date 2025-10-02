/*
 * LR_Gapcloser - Gap filling using ONT ultra-long reads
 * https://github.com/CAFS-bioinformatics/LR_Gapcloser
 */

process LR_GAPCLOSER {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}/scaffolding/gapcloser", mode: params.publish_dir_mode

    conda "bioconda::lr_gapcloser=1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lr_gapcloser:1.1--h9a82719_1' :
        'quay.io/biocontainers/lr_gapcloser:1.1--h9a82719_1' }"

    input:
    tuple val(meta), path(scaffolds), path(ont_reads)

    output:
    tuple val(meta), path("${prefix}.gapclosed.fasta"),    emit: assembly
    tuple val(meta), path("${prefix}.gapclosed.log"),      emit: log
    path "versions.yml",                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def min_length = params.lr_gapcloser_min_length ?: 80000
    def iterations = params.lr_gapcloser_iterations ?: 3

    """
    # Run LR_Gapcloser with iterative rounds
    LR_Gapcloser.sh \\
        -i ${scaffolds} \\
        -l ${ont_reads} \\
        -o ${prefix} \\
        -t ${task.cpus} \\
        -m ${min_length} \\
        -r ${iterations} \\
        ${args}

    # Rename output
    if [ -f "${prefix}/gapclosed.fa" ]; then
        mv ${prefix}/gapclosed.fa ${prefix}.gapclosed.fasta
    fi

    if [ -f "${prefix}/gapclosed.log" ]; then
        mv ${prefix}/gapclosed.log ${prefix}.gapclosed.log
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lr_gapcloser: \$(LR_Gapcloser.sh --version 2>&1 | grep version | cut -d' ' -f2 || echo "1.1")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.gapclosed.fasta
    touch ${prefix}.gapclosed.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lr_gapcloser: \$(echo "1.1")
    END_VERSIONS
    """
}
