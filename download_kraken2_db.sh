#!/bin/bash
# One-time database download. Run directly on the Roihu login node (just
# curl + tar, no compute/module needed) — not an sbatch job.
#
# PlusPF-8: RefSeq archaea/bacteria/viral/plasmid/human/UniVec_Core plus
# protozoa and fungi, capped to fit an ~8GB index. Chosen over the plain
# Standard-8 index (same size, same core content) because it also covers
# fungi/protozoa at no extra cost — useful for an open-ended "what even is
# this" contamination screen rather than a targeted pathogen search.
# Source: https://benlangmead.github.io/aws-indexes/k2 (Ben Langmead's
# pre-built Kraken2/Bracken index collection). URL verified reachable
# (HTTP 200, 5,933,654,083 bytes) on 2026-09-19 before writing this script.
#
# Usage: ./download_kraken2_db.sh

set -euo pipefail

BASE=/scratch/project_2019675/CW_metagenomic_screening
DB_DIR=$BASE/kraken2_db
URL="https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_08_GB_20260626.tar.gz"
TARBALL=$BASE/k2_pluspf_08gb.tar.gz

mkdir -p $DB_DIR

if [ -f "$DB_DIR/hash.k2d" ]; then
    echo "Database already present at $DB_DIR (hash.k2d exists) — skipping."
    exit 0
fi

echo "Downloading $URL ..."
curl -o $TARBALL "$URL"

echo "Extracting to $DB_DIR ..."
tar -xzf $TARBALL -C $DB_DIR

rm -f $TARBALL
echo "Done. Database ready at $DB_DIR"
du -sh $DB_DIR
