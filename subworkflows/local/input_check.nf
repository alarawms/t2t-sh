/*
 * Check input samplesheet and get read channels
 */

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    // Parse CSV and create channels for different read types
    Channel
        .fromPath(samplesheet)
        .splitCsv(header: true, sep: ',')
        .map { create_read_channels(it) }
        .set { parsed_input }

    // Separate channels by read type
    parsed_input
        .map { meta, reads -> [meta, reads.hifi] }
        .filter { meta, reads -> reads != null }
        .set { ch_hifi }

    parsed_input
        .map { meta, reads -> [meta, reads.ont] }
        .filter { meta, reads -> reads != null }
        .set { ch_ont }

    parsed_input
        .map { meta, reads -> [meta, reads.hic] }
        .filter { meta, reads -> reads != null }
        .set { ch_hic }

    emit:
    hifi = ch_hifi
    ont  = ch_ont
    hic  = ch_hic
}

/*
 * Function to parse samplesheet row and create meta map
 */
def create_read_channels(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id = row.sample
    meta.genome_size = row.genome_size ?: null

    // Create reads map
    def reads = [:]

    // HiFi reads (required)
    if (row.hifi_reads) {
        def hifi_file = file(row.hifi_reads, checkIfExists: true)
        reads.hifi = hifi_file
    } else {
        exit 1, "ERROR: HiFi reads are required for sample: ${row.sample}"
    }

    // ONT reads (optional)
    if (row.ont_reads && row.ont_reads != '') {
        def ont_file = file(row.ont_reads, checkIfExists: true)
        reads.ont = ont_file
    } else {
        reads.ont = null
    }

    // Hi-C reads (optional, paired)
    if (row.hic_reads_1 && row.hic_reads_1 != '' &&
        row.hic_reads_2 && row.hic_reads_2 != '') {
        def hic_r1 = file(row.hic_reads_1, checkIfExists: true)
        def hic_r2 = file(row.hic_reads_2, checkIfExists: true)
        reads.hic = [hic_r1, hic_r2]
    } else if ((row.hic_reads_1 && row.hic_reads_1 != '') ||
               (row.hic_reads_2 && row.hic_reads_2 != '')) {
        exit 1, "ERROR: Both Hi-C read pairs must be provided for sample: ${row.sample}"
    } else {
        reads.hic = null
    }

    return [meta, reads]
}
