#!/bin/bash
#SBATCH --job-name=subsample
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Pulls a random subsample of "off-target" (non-endogenous) reads per
# sample, for taxonomic classification (run_kraken2.sh). Two modes,
# chosen automatically per sample based on what's actually on disk in
# the_coffee_wrecks:
#
#   - Precise mode (R0003, R0004 as of 2026-09): their bwa-out/*_sorted.bam
#     still exists, so we extract true unmapped reads (samtools view -f 4)
#     and subsample from those directly.
#   - Approximate mode (R0002, R0005 as of 2026-09): their alignment BAMs
#     were deleted during a disk-quota cleanup (see the_coffee_wrecks
#     PIPELINE.md, 2026-09-03 entry). We subsample straight from the raw
#     fastq instead — since under 1% of reads map at all (see PIPELINE.md's
#     "Sample QC: signal/coverage funnel" section), a random raw-read
#     subsample is statistically indistinguishable from an unmapped-only
#     subsample for classification purposes. Same seed on R1/R2 via seqtk
#     keeps pairs in sync, though pairing doesn't matter much here since
#     reads are classified independently either way — output is pooled,
#     not kept as proper pairs.
#
# Usage: ./subsample_unmapped.sh <SAMPLE> [N_READS]
#   e.g. ./subsample_unmapped.sh CT600-007R0002 2000000

BASE=/scratch/project_2019675/CW_metagenomic_screening
CW=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load samtools/1.21
module load seqtk/1.4

SAMPLE=$1
N_READS=${2:-2000000}
OUTDIR=$BASE/results/$SAMPLE
SORTED_BAM=$CW/bwa-out/${SAMPLE}_sorted.bam
SEED=42

mkdir -p $OUTDIR

if [ -f "$SORTED_BAM" ]; then
    echo "Precise mode: extracting true unmapped reads from $SORTED_BAM"
    UNMAPPED_FQ=$OUTDIR/${SAMPLE}_unmapped_all.fq
    samtools view -@ 2 -f 4 -b "$SORTED_BAM" | samtools fastq -@ 2 - > "$UNMAPPED_FQ"
    seqtk sample -s$SEED "$UNMAPPED_FQ" $N_READS > $OUTDIR/${SAMPLE}_subsample.fq
    rm -f "$UNMAPPED_FQ"
else
    echo "Approximate mode: no sorted.bam found (likely cleaned up), subsampling raw fastq instead"
    R1=$CW/vrouw_maria_2026_segments/Unknown_${SAMPLE}_1.fq.gz
    R2=$CW/vrouw_maria_2026_segments/Unknown_${SAMPLE}_2.fq.gz
    HALF=$((N_READS / 2))
    seqtk sample -s$SEED "$R1" $HALF > $OUTDIR/${SAMPLE}_subsample.fq
    seqtk sample -s$SEED "$R2" $HALF >> $OUTDIR/${SAMPLE}_subsample.fq
fi

gzip -f $OUTDIR/${SAMPLE}_subsample.fq
echo "Wrote $OUTDIR/${SAMPLE}_subsample.fq.gz"
zcat $OUTDIR/${SAMPLE}_subsample.fq.gz | wc -l | awk '{print "  " $1/4 " reads"}'
