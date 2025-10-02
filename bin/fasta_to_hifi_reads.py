#!/usr/bin/env python3
"""
Convert FASTA genome to simulated HiFi reads
Creates realistic 15kb reads with 20x coverage
"""

import gzip
import random
import sys

def read_fasta(filename):
    """Read FASTA file and return sequence"""
    sequence = []
    with gzip.open(filename, 'rt') as f:
        for line in f:
            if not line.startswith('>'):
                sequence.append(line.strip())
    return ''.join(sequence)

def generate_quality(length, mean_q=30):
    """Generate PHRED quality scores"""
    quals = []
    for _ in range(length):
        q = max(20, min(40, int(random.gauss(mean_q, 5))))
        quals.append(chr(q + 33))
    return ''.join(quals)

def main():
    if len(sys.argv) != 4:
        print("Usage: fasta_to_hifi_reads.py <input.fna.gz> <output.fastq.gz> <coverage>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    coverage = int(sys.argv[3])

    print(f"Reading genome from {input_file}...")
    genome = read_fasta(input_file)
    genome_len = len(genome)

    read_length = 15000
    num_reads = int(genome_len * coverage / read_length)

    print(f"Genome size: {genome_len/1e6:.2f} Mb")
    print(f"Generating {num_reads} reads for {coverage}x coverage...")

    with gzip.open(output_file, 'wt') as out:
        for i in range(num_reads):
            start = random.randint(0, genome_len - read_length)
            read_seq = genome[start:start + read_length]
            qual_str = generate_quality(read_length)

            out.write(f"@read_{i+1}/ccs\n")
            out.write(f"{read_seq}\n")
            out.write("+\n")
            out.write(f"{qual_str}\n")

            if (i + 1) % 50 == 0:
                print(f"  Generated {i+1}/{num_reads} reads...", end='\r')

    print(f"\n✓ Created {output_file}")

if __name__ == '__main__':
    main()
