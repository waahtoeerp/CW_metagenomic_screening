#!/bin/bash
# Run directly on the Roihu login node — not an sbatch job.
#
# `kraken2-build --download-taxonomy` uses rsync (port 873) against
# ftp.ncbi.nlm.nih.gov, which is blocked outbound on this cluster
# (confirmed 2026-09-19: "Connection refused" both from a login-node shell
# and from inside an sbatch job — this is a network-wide protocol block,
# not a compute-vs-login-node restriction). NCBI serves the identical
# taxdump.tar.gz over plain HTTPS on the same host, which curl already
# works with elsewhere in this project, so we fetch it directly and skip
# kraken2-build's downloader entirely. We also skip the accession2taxid
# maps (kraken2-build's KRAKEN2_SKIP_MAPS) since build_coffee_kraken2_db.sh
# assigns taxids explicitly via `kraken:taxid|` FASTA header tags instead.
#
# Usage: ./download_coffee_taxonomy.sh

set -euo pipefail

BASE=/scratch/project_2019675/CW_metagenomic_screening
DB=$BASE/coffee_kraken2_db
TAXONOMY_DIR=$DB/taxonomy

if [ -f "$TAXONOMY_DIR/nodes.dmp" ]; then
    echo "Taxonomy already present at $TAXONOMY_DIR — skipping."
    exit 0
fi

mkdir -p $TAXONOMY_DIR
curl -o $BASE/taxdump.tar.gz "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz"
tar -xzf $BASE/taxdump.tar.gz -C $TAXONOMY_DIR
rm -f $BASE/taxdump.tar.gz

echo "Done."
ls $TAXONOMY_DIR
