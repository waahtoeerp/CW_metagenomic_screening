#!/bin/bash
# Shared module setup for this repo on Roihu — same fix as
# the_coffee_wrecks/load_modules.sh (standalone copy, not shared across
# repos on purpose — these are meant to be independent).
#
# Roihu's login/job shells auto-load a default StdEnv toolchain (gcc,
# openmpi, ucx, openblas) that's incompatible with the bio-apps/v202603
# tree (samtools/seqtk/kraken2/etc all live there). `module load
# bio-apps/v202603` on top of StdEnv succeeds silently, but every tool
# inside it then fails to resolve until StdEnv is unloaded first.
#
# Usage: source $BASE/load_modules.sh, then module load <tool>/<version>.

module purge
module load bio-apps/v202603
