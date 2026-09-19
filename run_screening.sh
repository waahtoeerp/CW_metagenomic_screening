#!/bin/bash
# Orchestrates the screening chain (subsample -> kraken2) per sample,
# mirroring the_coffee_wrecks/run_pipeline.sh's pattern. Assumes
# download_kraken2_db.sh has already been run once (not included in this
# chain — it's a one-time login-node step, not a compute job).
#
# Run this from the login node:
#   ./run_screening.sh                              # all 4 samples
#   ./run_screening.sh CT600-007R0002 CT600-007R0005 # just these samples

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ ! -f "$DIR/kraken2_db/hash.k2d" ]; then
    echo "Kraken2 database not found — run ./download_kraken2_db.sh first." >&2
    exit 1
fi

if [ "$#" -gt 0 ]; then
    SAMPLES=("$@")
else
    SAMPLES=(CT600-007R0002 CT600-007R0003 CT600-007R0004 CT600-007R0005)
fi

for SAMPLE in "${SAMPLES[@]}"; do
    echo "Submitting screening chain for $SAMPLE..."
    jid_sub=$(sbatch --parsable --job-name=subsample_$SAMPLE subsample_unmapped.sh "$SAMPLE")
    jid_kraken=$(sbatch --parsable --job-name=kraken2_$SAMPLE --dependency=afterok:$jid_sub run_kraken2.sh "$SAMPLE")
    echo "  $SAMPLE: subsample=$jid_sub kraken2=$jid_kraken"
done

cat <<EOF

Check status with: squeue -u \$USER
Reports land in results/\${SAMPLE}/\${SAMPLE}_kraken2_report.txt
EOF
