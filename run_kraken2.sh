#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Classifies the subsample (subsample_unmapped.sh) against the PlusPF-8
# database (download_kraken2_db.sh). 16G mem requested for headroom over
# the ~8GB index; --cpus-per-task=4 for kraken2's -t threading.
#
# Usage: ./run_kraken2.sh <SAMPLE>

BASE=/scratch/project_2019675/CW_metagenomic_screening
source $BASE/load_modules.sh
module load kraken2/2.17.1

SAMPLE=$1
DB_DIR=$BASE/kraken2_db
OUTDIR=$BASE/results/$SAMPLE
FQ=$OUTDIR/${SAMPLE}_subsample.fq.gz

if [ ! -f "$DB_DIR/hash.k2d" ]; then
    echo "Kraken2 database not found at $DB_DIR — run download_kraken2_db.sh first." >&2
    exit 1
fi
if [ ! -f "$FQ" ]; then
    echo "$FQ not found — run subsample_unmapped.sh $SAMPLE first." >&2
    exit 1
fi

kraken2 --db $DB_DIR \
    --threads 4 \
    --report $OUTDIR/${SAMPLE}_kraken2_report.txt \
    --output $OUTDIR/${SAMPLE}_kraken2_output.txt \
    --use-names \
    $FQ

echo "Top 20 taxa by read count:"
sort -t$'\t' -k3,3 -rn $OUTDIR/${SAMPLE}_kraken2_report.txt | head -20
