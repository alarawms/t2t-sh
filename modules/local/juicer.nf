/*
 * Juicer - Hi-C read alignment and contact map generation
 * https://github.com/aidenlab/juicer
 */

process JUICER {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}/scaffolding/juicer", mode: params.publish_dir_mode

    conda "bioconda::juicer=1.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/juicer:1.6--hdfd78af_1' :
        'quay.io/biocontainers/juicer:1.6--hdfd78af_1' }"

    input:
    tuple val(meta), path(assembly), path(hic_reads_1), path(hic_reads_2)

    output:
    tuple val(meta), path("${prefix}/aligned"),          emit: alignments
    tuple val(meta), path("${prefix}/aligned/merged_nodups.txt"), emit: merged_nodups
    tuple val(meta), path("${prefix}/*.hic"),            emit: hic_file, optional: true
    path "versions.yml",                                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def mapq = params.juicer_mapq ?: 30

    """
    # Create Juicer directory structure
    mkdir -p ${prefix}/fastq
    mkdir -p ${prefix}/splits
    mkdir -p ${prefix}/aligned
    mkdir -p ${prefix}/references

    # Link Hi-C reads
    ln -s ${hic_reads_1} ${prefix}/fastq/reads_R1.fastq.gz
    ln -s ${hic_reads_2} ${prefix}/fastq/reads_R2.fastq.gz

    # Link assembly as reference
    ln -s ${assembly} ${prefix}/references/assembly.fasta

    # Index assembly with BWA
    bwa index ${prefix}/references/assembly.fasta

    # Generate restriction site file for assembly
    python3 <<CODE
import re
with open("${prefix}/references/assembly.fasta", "r") as f:
    content = f.read()
    # Extract chromosome sizes
    chrom_sizes = {}
    for match in re.finditer(r'>([^\\n]+)\\n([^>]+)', content):
        chrom_id = match.group(1).split()[0]
        seq = match.group(2).replace('\\n', '')
        chrom_sizes[chrom_id] = len(seq)

    # Write chromosome sizes file
    with open("${prefix}/references/assembly.chrom.sizes", "w") as out:
        for chrom, size in chrom_sizes.items():
            out.write(f"{chrom}\\t{size}\\n")
CODE

    # Run Juicer CPU pipeline
    cd ${prefix}

    # Align Hi-C reads with BWA
    bwa mem -t ${task.cpus} -SP5M references/assembly.fasta \\
        fastq/reads_R1.fastq.gz fastq/reads_R2.fastq.gz | \\
        samtools view -@ ${task.cpus} -bS - | \\
        samtools sort -@ ${task.cpus} -n - > aligned/aligned.bam

    # Convert to Juicer format and filter by MAPQ
    samtools view -@ ${task.cpus} aligned/aligned.bam | \\
        awk -v mapq=${mapq} 'BEGIN{OFS="\\t"} \\
            \$5 >= mapq {print \$1, \$3, \$4, 0, \$7, \$8, 0, 0}' | \\
        sort -k2,2 -k6,6 -k4,4n -k8,8n --parallel=${task.cpus} -S 50% > \\
        aligned/merged_nodups.txt

    cd ..

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        juicer: \$(echo "1.6")
        bwa: \$(bwa 2>&1 | grep Version | cut -d' ' -f2)
        samtools: \$(samtools --version 2>&1 | grep samtools | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}/aligned
    touch ${prefix}/aligned/merged_nodups.txt
    touch ${prefix}/assembly.hic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        juicer: \$(echo "1.6")
        bwa: \$(bwa 2>&1 | grep Version | cut -d' ' -f2)
    END_VERSIONS
    """
}
