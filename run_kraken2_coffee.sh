#!/bin/bash
#SBATCH --job-name=kraken2_coffee
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Second classification pass, against the small dedicated coffee_kraken2_db/
# (build_coffee_kraken2_db.sh) instead of the broad kraken2_db/ (PlusPF-8,
# run_kraken2.sh). Same subsample as the PlusPF-8 pass -- reuses
# subsample_unmapped.sh's output, doesn't resample.
#
# --output additionally lets us grep out exactly which reads classified,
# for follow-up (e.g. extracting them for mapDamage).
#
# Usage: ./run_kraken2_coffee.sh <SAMPLE>

BASE=/scratch/project_2019675/CW_metagenomic_screening
source $BASE/load_modules.sh
module load kraken2/2.17.1

SAMPLE=$1
DB_DIR=$BASE/coffee_kraken2_db
OUTDIR=$BASE/results/$SAMPLE
FQ=$OUTDIR/${SAMPLE}_subsample.fq.gz

if [ ! -f "$DB_DIR/hash.k2d" ]; then
    echo "Coffee database not found at $DB_DIR — run build_coffee_kraken2_db.sh first." >&2
    exit 1
fi
if [ ! -f "$FQ" ]; then
    echo "$FQ not found — run subsample_unmapped.sh $SAMPLE first." >&2
    exit 1
fi

kraken2 --db $DB_DIR \
    --threads 4 \
    --report $OUTDIR/${SAMPLE}_kraken2_coffee_report.txt \
    --output $OUTDIR/${SAMPLE}_kraken2_coffee_output.txt \
    --use-names \
    $FQ

echo "Coffee-genus classification report:"
cat $OUTDIR/${SAMPLE}_kraken2_coffee_report.txt || true
