#!/usr/bin/env python3
"""
Generate synthetic E. coli HiFi-like test data
Creates realistic HiFi reads for testing the assembly pipeline
"""

import random
import gzip

def generate_hifi_read(genome_seq, read_length=15000, error_rate=0.001):
    """Generate a single HiFi read with realistic characteristics"""
    genome_len = len(genome_seq)
    start = random.randint(0, genome_len - read_length)
    read = genome_seq[start:start + read_length]

    # Add HiFi-level errors (very low)
    read_list = list(read)
    for i in range(len(read_list)):
        if random.random() < error_rate:
            read_list[i] = random.choice(['A', 'C', 'G', 'T'])

    return ''.join(read_list)

def generate_quality_string(length, mean_quality=30):
    """Generate PHRED quality scores for HiFi reads (Q20-Q40)"""
    qualities = []
    for _ in range(length):
        q = int(random.gauss(mean_quality, 5))
        q = max(20, min(40, q))  # Clamp to HiFi range
        qualities.append(chr(q + 33))
    return ''.join(qualities)

def main():
    # Simple E. coli K12 genome fragment (4.6Mb represented by repeating pattern)
    # Real E. coli has complex structure, this is simplified for testing
    ecoli_fragment = (
        "AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC" * 100 +
        "TTACCGGATACGCTATCCGAAATTCATTCGGATACGCTTATGCGATTAGCTTACGATTACGATCGATCGA" * 100 +
        "CGCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGAT" * 100 +
        "ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGAT" * 100
    )

    # Extend to 500kb for realistic assembly testing
    genome = ecoli_fragment * 20
    genome_size = len(genome)

    # Generate 10x coverage with HiFi reads
    read_length = 15000
    num_reads = int(genome_size * 10 / read_length)

    print(f"Generating {num_reads} HiFi reads for {genome_size/1000:.1f}kb genome (~10x coverage)")

    with gzip.open('/home/alarawms/nfs/dev/t2t-sh/test_data/ecoli_synthetic_hifi.fastq.gz', 'wt') as f:
        for i in range(num_reads):
            read_seq = generate_hifi_read(genome, read_length)
            qual_str = generate_quality_string(len(read_seq))

            f.write(f"@read_{i+1}/ccs\n")
            f.write(f"{read_seq}\n")
            f.write("+\n")
            f.write(f"{qual_str}\n")

            if (i + 1) % 10 == 0:
                print(f"  Generated {i+1}/{num_reads} reads...", end='\r')

    print(f"\n✓ Created ecoli_synthetic_hifi.fastq.gz ({num_reads} reads, ~10x coverage)")
    print(f"  Genome size: {genome_size/1000:.1f}kb")
    print(f"  Expected assembly size: ~{genome_size/1000:.1f}kb")

if __name__ == '__main__':
    main()
