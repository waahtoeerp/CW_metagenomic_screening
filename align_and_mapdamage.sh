#!/bin/bash
#SBATCH --job-name=coffee_hits_mapdamage
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=00:20:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Aligns extract_coffee_hits.sh's output (reads Kraken2 classified as
# Coffea but bwa never mapped) to the C. arabica reference, then runs
# mapDamage. Same bwa aln parameters as the_coffee_wrecks/bwa-vrouw.sh
# (-l 16500 -n 0.01, seed disabled -- see that repo's PIPELINE.md "bwa aln
# parameters" section) for direct comparability. The question: do these
# reads show the same 5' C->T / 3' G->A deamination signature already
# confirmed elsewhere in the_coffee_wrecks? If yes, genuinely ancient
# coffee DNA the base pipeline missed. If not (flat/absent damage curve),
# more likely a modern contaminant that happens to classify as Coffea
# (e.g. a lab reagent) rather than recovered aDNA signal.
#
# Sample sizes here are tiny (hundreds of reads) -- mapDamage's Bayesian
# rescaling model wants more data than that to fit robustly, but the basic
# empirical misincorporation-frequency plot (5pCtoT_freq.txt etc.) doesn't
# need nearly as much and should still be informative.
#
# Usage: ./align_and_mapdamage.sh <SAMPLE>

BASE=/scratch/project_2019675/CW_metagenomic_screening
CW=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load bwa/0.7.19
module load samtools/1.21
module load mapdamage2/2.2.3

SAMPLE=$1
REF=$CW/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna
OUTDIR=$BASE/results/$SAMPLE
FQ=$OUTDIR/${SAMPLE}_coffee_hits.fq.gz

bwa aln -l 16500 -n 0.01 -t 2 $REF $FQ > $OUTDIR/${SAMPLE}_coffee_hits.sai
bwa samse $REF $OUTDIR/${SAMPLE}_coffee_hits.sai $FQ \
    | samtools view -bS \
    | samtools sort -o $OUTDIR/${SAMPLE}_coffee_hits_sorted.bam
samtools index $OUTDIR/${SAMPLE}_coffee_hits_sorted.bam

N_MAPPED=$(samtools view -c -F 4 $OUTDIR/${SAMPLE}_coffee_hits_sorted.bam)
echo "$N_MAPPED of $(zcat $FQ | wc -l | awk '{print $1/4}') coffee-classified reads aligned to the C. arabica reference"

if [ "$N_MAPPED" -lt 10 ]; then
    echo "Too few aligned reads for mapDamage to produce anything meaningful — stopping here."
    exit 0
fi

mapDamage -i $OUTDIR/${SAMPLE}_coffee_hits_sorted.bam -r $REF \
    --folder $OUTDIR/${SAMPLE}_coffee_hits_mapDamage

echo "=== 5' C->T frequency (first 10 positions) ==="
head -11 $OUTDIR/${SAMPLE}_coffee_hits_mapDamage/5pCtoT_freq.txt
echo "=== 3' G->A frequency (first 10 positions) ==="
head -11 $OUTDIR/${SAMPLE}_coffee_hits_mapDamage/3pGtoA_freq.txt
