#!/bin/bash
#SBATCH --job-name=posctrl
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Positive control for the coffee Kraken2 database: take the reads the base
# pipeline already aligned to C. arabica (deduplicated, rescaled BAM from
# the_coffee_wrecks/mapDamage-out/) and confirm Kraken2 classifies them as
# Coffea. If it doesn't, the database or Kraken2 setup is broken and the
# negative screening result can't be trusted.
#
# Caveat: the reference is part of the coffee database, so this is a
# self-consistency check, not evidence of anything new.
#
# Usage: sbatch positive_control.sh <SAMPLE> [DB_NAME]
#   DB_NAME defaults to coffee_kraken2_db (includes ET-39 -- circular, see above).
#   Use parents_kraken2_db for the sanity check without the reference.

BASE=/scratch/project_2019675/CW_metagenomic_screening
CW=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load kraken2/2.17.1
module load samtools/1.21

SAMPLE=$1
DB_NAME=${2:-coffee_kraken2_db}
BAM=$CW/mapDamage-out/${SAMPLE}_mapDamage_dedup/${SAMPLE}_dedup.rescaled.bam
MAPPED_DIR=$BASE/results/$SAMPLE/positive_control
OUTDIR=$MAPPED_DIR/$DB_NAME
DB_DIR=$BASE/$DB_NAME
FQ=$MAPPED_DIR/${SAMPLE}_mapped.fq.gz

if [ ! -f "$BAM" ]; then
    echo "Missing $BAM -- run the_coffee_wrecks mapDamage_rescale.sh for $SAMPLE first." >&2
    exit 1
fi
if [ ! -f "$DB_DIR/hash.k2d" ]; then
    echo "Coffee database not found at $DB_DIR -- run build_coffee_kraken2_db.sh first." >&2
    exit 1
fi

mkdir -p "$OUTDIR"

# -F 0x904: drop unmapped, secondary and supplementary records
samtools fastq -F 0x904 "$BAM" | gzip > "$FQ"

kraken2 --db "$DB_DIR" \
    --threads 4 \
    --report "$OUTDIR/${SAMPLE}_report.txt" \
    --output "$OUTDIR/${SAMPLE}_output.txt" \
    --use-names \
    "$FQ"

# Report columns: pct, clade reads, direct reads, rank, taxid, name.
# taxid 1 = root (all classified reads), taxid 0 = unclassified, 13442 = Coffea genus.
read -r TOTAL COFFEA UNCLASS <<< "$(awk -F'\t' '
    $5==1 {t=$2}
    $5==13442 {c=$2}
    $5==0 {u=$2}
    END {print t+0, c+0, u+0}' "$OUTDIR/${SAMPLE}_report.txt")"

if [ "$TOTAL" -eq 0 ]; then
    echo "FAIL: $SAMPLE -- no mapped reads were classified (empty input, or Kraken2 found nothing)." >&2
    exit 1
fi

PCT=$(awk -v c="$COFFEA" -v t="$TOTAL" 'BEGIN {printf "%.1f", 100*c/t}')
echo "$SAMPLE: $TOTAL mapped reads, $COFFEA classified as Coffea (${PCT}%), $UNCLASS unclassified"

if [ "$COFFEA" -eq 0 ]; then
    echo "FAIL: $SAMPLE -- positive control found zero Coffea reads; database or Kraken2 setup is broken." >&2
    exit 1
fi
