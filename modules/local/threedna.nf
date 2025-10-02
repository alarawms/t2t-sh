/*
 * 3D-DNA - Chromosome-level scaffolding using Hi-C data
 * https://github.com/aidenlab/3d-dna
 */

process THREEDNA {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}/scaffolding/3ddna", mode: params.publish_dir_mode

    conda "bioconda::3d-dna=201008"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/3d-dna:201008--hdfd78af_0' :
        'quay.io/biocontainers/3d-dna:201008--hdfd78af_0' }"

    input:
    tuple val(meta), path(assembly), path(merged_nodups)

    output:
    tuple val(meta), path("${prefix}.FINAL.fasta"),           emit: scaffolds
    tuple val(meta), path("${prefix}.FINAL.assembly"),        emit: assembly_file
    tuple val(meta), path("${prefix}.FINAL.hic"),             emit: hic_file, optional: true
    tuple val(meta), path("${prefix}_*.assembly"),            emit: intermediate, optional: true
    path "versions.yml",                                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def rounds = params.threedna_rounds ?: 3

    """
    # 3D-DNA requires specific input names
    ln -s ${assembly} assembly.fasta
    ln -s ${merged_nodups} merged_nodups.txt

    # Run 3D-DNA pipeline with iterative rounds
    run-asm-pipeline.sh \\
        -r ${rounds} \\
        ${args} \\
        assembly.fasta \\
        merged_nodups.txt

    # Rename outputs to include sample prefix
    if [ -f "assembly.FINAL.fasta" ]; then
        mv assembly.FINAL.fasta ${prefix}.FINAL.fasta
    fi

    if [ -f "assembly.FINAL.assembly" ]; then
        mv assembly.FINAL.assembly ${prefix}.FINAL.assembly
    fi

    if [ -f "assembly.FINAL.hic" ]; then
        mv assembly.FINAL.hic ${prefix}.FINAL.hic
    fi

    # Capture intermediate assemblies if they exist
    for f in assembly_*.assembly; do
        if [ -f "\$f" ]; then
            base=\$(basename \$f .assembly)
            mv "\$f" "${prefix}_\${base#assembly_}.assembly"
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        3d-dna: \$(echo "201008")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.FINAL.fasta
    touch ${prefix}.FINAL.assembly
    touch ${prefix}.FINAL.hic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        3d-dna: \$(echo "201008")
    END_VERSIONS
    """
}
