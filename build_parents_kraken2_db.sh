#!/bin/bash
#SBATCH --job-name=build_parents_db
#SBATCH --account=project_2019675
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=eero.saarinen@helsinki.fi

set -euo pipefail

# Sanity-check database: the two diploid parents of C. arabica only, with
# the ET-39 reference deliberately left out. Used by positive_control.sh to
# check whether Kraken2 still recognizes arabica-derived reads through a
# related genome, rather than through the exact reference (which is in
# coffee_kraken2_db/ and would make the check circular).
#
# Requires coffee_kraken2_db/taxonomy (build_coffee_kraken2_db.sh or
# download_coffee_taxonomy.sh).
#
# Usage: ./build_parents_kraken2_db.sh

BASE=/scratch/project_2019675/CW_metagenomic_screening
source $BASE/load_modules.sh
module load kraken2/2.17.1

DB=$BASE/parents_kraken2_db
REFS=$BASE/coffee_refs
TAX_SRC=$BASE/coffee_kraken2_db/taxonomy

for f in "$REFS/GCA_036785865.1_tagged.fna" "$REFS/GCF_003713205.1_tagged.fna"; do
    [ -f "$f" ] || { echo "Missing $f -- build_coffee_kraken2_db.sh tags these first." >&2; exit 1; }
done
[ -f "$TAX_SRC/nodes.dmp" ] || { echo "Taxonomy not found at $TAX_SRC -- run download_coffee_taxonomy.sh first." >&2; exit 1; }

mkdir -p "$DB"
if [ ! -d "$DB/taxonomy" ]; then
    cp -r "$TAX_SRC" "$DB/taxonomy"
fi

echo "Adding C. canephora (taxid 49390)..."
kraken2-build --add-to-library "$REFS/GCA_036785865.1_tagged.fna" --db $DB

echo "Adding C. eugenioides (taxid 49369)..."
kraken2-build --add-to-library "$REFS/GCF_003713205.1_tagged.fna" --db $DB

echo "Building database..."
kraken2-build --build --db $DB --threads 4
kraken2-build --clean --db $DB

echo "Done."
du -sh $DB
