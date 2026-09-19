#!/bin/bash
#SBATCH --job-name=build_coffee_db
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Builds a small, dedicated Kraken2 database containing just Coffea arabica
# and its two diploid parental species (C. arabica is a natural allo-
# tetraploid hybrid of these two -- see README.md "Genome sources" for
# citations). Deliberately kept separate from kraken2_db/ (the PlusPF-8
# download): that database's raw source library isn't included in the
# distributed tarball (only the compiled hash.k2d/taxo.k2d), so the
# standard add-to-library+rebuild workflow would discard its existing 8GB
# of bacterial/viral/human/fungi/protozoa references and rebuild from just
# these 3 genomes. Two separate classification passes (against kraken2_db/
# for the broad contamination picture, against coffee_kraken2_db/ for a
# direct "does this look like coffee" answer) avoids that entirely, and is
# arguably cleaner anyway -- one unambiguous signal per question.
#
# Usage: ./build_coffee_kraken2_db.sh

BASE=/scratch/project_2019675/CW_metagenomic_screening
CW=/scratch/project_2019675/the_coffee_wrecks
source $BASE/load_modules.sh
module load kraken2/2.17.1

DB=$BASE/coffee_kraken2_db
REFS=$BASE/coffee_refs

mkdir -p $REFS

if [ ! -d "$DB/taxonomy" ]; then
    echo "Downloading NCBI taxonomy..."
    kraken2-build --download-taxonomy --db $DB
fi

# Tag each genome's FASTA headers with its NCBI taxid so kraken2-build
# assigns them directly, bypassing the (unneeded, much larger) NCBI
# accession2taxid mapping download.
tag_and_add () {
    local src=$1 taxid=$2 tagged=$3
    if [ ! -f "$tagged" ]; then
        zcat -f "$src" | sed -E "s/^>(\S+)/>\1|kraken:taxid|${taxid}/" > "$tagged"
    fi
    kraken2-build --add-to-library "$tagged" --db $DB
}

echo "Adding C. arabica (GCF_036785885.1, taxid 13443)..."
tag_and_add "$CW/ref_gen/GCF_036785885.1_Coffea_Arabica_ET-39_HiFi_genomic.fna" \
    13443 "$REFS/GCF_036785885.1_tagged.fna"

echo "Adding C. canephora (GCA_036785865.1, taxid 49390)..."
tag_and_add "$REFS/GCA_036785865.1_ASM3678586v1_genomic.fna.gz" \
    49390 "$REFS/GCA_036785865.1_tagged.fna"

echo "Adding C. eugenioides (GCF_003713205.1, taxid 49369)..."
tag_and_add "$REFS/GCF_003713205.1_Ceug_1.0_genomic.fna.gz" \
    49369 "$REFS/GCF_003713205.1_tagged.fna"

echo "Building database..."
kraken2-build --build --db $DB --threads 4

kraken2-build --clean --db $DB
echo "Done."
du -sh $DB
