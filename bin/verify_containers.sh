#!/usr/bin/env bash
#
# Verify that all container images exist and are accessible
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Container images used in pipeline
CONTAINERS=(
    "quay.io/biocontainers/hifiasm:0.25.0--h5ca1c30_0"
    "quay.io/biocontainers/busco:5.8.3--pyhdfd78af_1"
    "quay.io/biocontainers/gawk:5.1.0"
)

print_header "Container Image Verification"

echo "Checking availability of container images..."
echo ""

ERRORS=0

for container in "${CONTAINERS[@]}"; do
    print_info "Checking: $container"

    # Extract registry and image
    if [[ $container == quay.io/* ]]; then
        # Remove quay.io/ and split by :
        image_path="${container#quay.io/}"
        repo="${image_path%:*}"
        tag="${image_path#*:}"

        # Check if image exists on Quay.io
        url="https://quay.io/api/v1/repository/${repo}/tag/${tag}/images"

        if curl -sf "$url" > /dev/null 2>&1; then
            print_success "Available: $container"
        else
            print_error "NOT FOUND: $container"
            ERRORS=$((ERRORS + 1))
        fi
    else
        print_info "Skipping non-quay.io image: $container"
    fi
    echo ""
done

echo ""
print_header "Summary"

if [ $ERRORS -eq 0 ]; then
    print_success "All $((${#CONTAINERS[@]})) container images are available!"
    echo ""
    echo "You can now run the pipeline with:"
    echo "  nextflow run main.nf -profile docker --input samples.csv"
    exit 0
else
    print_error "Found $ERRORS missing container image(s)"
    echo ""
    echo "Please check the container tags or update modules to use available versions."
    echo "Visit https://quay.io/repository/biocontainers/ to find available tags."
    exit 1
fi
