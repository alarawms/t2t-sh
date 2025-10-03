/*
 * TGS-GapCloser - Gap filling using ONT/PacBio long reads
 * https://github.com/BGI-Qingdao/TGS-GapCloser
 * Superior to LR_Gapcloser with better accuracy and speed
 */

process TGSGAPCLOSER {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}/scaffolding/gapcloser", mode: params.publish_dir_mode

    conda "bioconda::tgsgapcloser=1.2.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tgsgapcloser:1.2.1--h5b5514e_1' :
        'quay.io/biocontainers/tgsgapcloser:1.2.1--h5b5514e_1' }"

    input:
    tuple val(meta), path(scaffolds), path(ont_reads)

    output:
    tuple val(meta), path("${prefix}.gapclosed.fasta"),    emit: assembly
    tuple val(meta), path("${prefix}.gapclosed.log"),      emit: log
    tuple val(meta), path("${prefix}.fill_details.txt"),   emit: details, optional: true
    path "versions.yml",                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def min_length = params.tgs_min_length ?: 5000
    def min_match = params.tgs_min_match ?: 0.3

    """
    # TGS-GapCloser command
    tgsgapcloser \\
        --scaff ${scaffolds} \\
        --reads ${ont_reads} \\
        --output ${prefix} \\
        --thread ${task.cpus} \\
        --min_read_len ${min_length} \\
        --min_match ${min_match} \\
        --ne \\
        ${args}

    # Rename outputs
    if [ -f "${prefix}.scaff_seqs" ]; then
        mv ${prefix}.scaff_seqs ${prefix}.gapclosed.fasta
    fi

    # Create log file
    echo "TGS-GapCloser completed successfully" > ${prefix}.gapclosed.log
    echo "Min read length: ${min_length}" >> ${prefix}.gapclosed.log
    echo "Min match ratio: ${min_match}" >> ${prefix}.gapclosed.log

    # Copy fill details if exists
    if [ -f "${prefix}.fill_details.txt" ]; then
        cp ${prefix}.fill_details.txt ${prefix}.fill_details.txt
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tgsgapcloser: \$(tgsgapcloser --version 2>&1 | grep version | cut -d' ' -f2 || echo "1.2.1")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.gapclosed.fasta
    touch ${prefix}.gapclosed.log
    touch ${prefix}.fill_details.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tgsgapcloser: \$(echo "1.2.1")
    END_VERSIONS
    """
}
