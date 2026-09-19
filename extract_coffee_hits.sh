#!/bin/bash
# Run directly on the Roihu login node — tiny amount of data (hundreds of
# reads), no need for sbatch.
#
# Pulls out just the reads run_kraken2_coffee.sh classified as Coffea
# (genus 13442, or species 13443/49390/49369), for mapDamage authentication
# (extract_coffee_hits.sh -> align to C. arabica -> mapDamage).
#
# Column 3 of kraken2 --output is "Name (taxid N)" for classified (C) rows
# -- must filter on that column specifically, not just grep the whole line,
# since column 5 (the per-k-mer LCA trace) can mention the same taxid on
# reads that were NOT actually classified there.
#
# Usage: ./extract_coffee_hits.sh <SAMPLE>

set -euo pipefail

BASE=/scratch/project_2019675/CW_metagenomic_screening
source $BASE/load_modules.sh
module load seqtk/1.4

SAMPLE=$1
OUTDIR=$BASE/results/$SAMPLE
KOUT=$OUTDIR/${SAMPLE}_kraken2_coffee_output.txt
FQ=$OUTDIR/${SAMPLE}_subsample.fq.gz

awk -F'\t' '$1=="C" && $3 ~ /\(taxid (13442|13443|49390|49369)\)/ {print $2}' "$KOUT" \
    > $OUTDIR/${SAMPLE}_coffee_hit_ids.txt

N=$(wc -l < $OUTDIR/${SAMPLE}_coffee_hit_ids.txt)
echo "$N reads classified as Coffea/species"

seqtk subseq "$FQ" $OUTDIR/${SAMPLE}_coffee_hit_ids.txt > $OUTDIR/${SAMPLE}_coffee_hits.fq
gzip -f $OUTDIR/${SAMPLE}_coffee_hits.fq
echo "Wrote $OUTDIR/${SAMPLE}_coffee_hits.fq.gz"
