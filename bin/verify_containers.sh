#!/bin/bash
# Verify all Singularity containers exist and are accessible

set -e

echo "Verifying Phase 3 Singularity containers..."
echo "============================================="

CONTAINERS=(
    "https://depot.galaxyproject.org/singularity/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:8110a70be2bfe7f75a2ea7f2a89cda4cc7732095-0"
    "https://depot.galaxyproject.org/singularity/3d-dna:201008--h779adbc_1"
    "https://depot.galaxyproject.org/singularity/tgsgapcloser:1.2.1--h43eeafb_0"
)

NAMES=(
    "BWA+Samtools (Juicer)"
    "3D-DNA"
    "TGS-GapCloser"
)

SUCCESS=0
FAILED=0

for i in "${!CONTAINERS[@]}"; do
    URL="${CONTAINERS[$i]}"
    NAME="${NAMES[$i]}"

    echo ""
    echo "Checking: $NAME"
    echo "URL: $URL"

    # Check if URL is accessible
    if curl --head --silent --fail "$URL" > /dev/null 2>&1; then
        echo "✓ Container exists and is accessible"
        ((SUCCESS++))
    else
        echo "✗ Container NOT accessible"
        ((FAILED++))
    fi
done

echo ""
echo "============================================="
echo "Results: $SUCCESS accessible, $FAILED failed"
echo "============================================="

if [ $FAILED -gt 0 ]; then
    echo "ERROR: Some containers are not accessible!"
    exit 1
else
    echo "SUCCESS: All containers verified!"
    exit 0
fi
