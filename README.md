# CW_metagenomic_screening

Metagenomic screening of the off-target (non-*Coffea*) reads from the [the_coffee_wrecks](https://github.com/waahtoeerp/the_coffee_wrecks) aDNA pipeline.

## Why this exists

Across all 4 samples, under 1% of raw sequencing reads map to the *Coffea arabica* reference genome — see `the_coffee_wrecks/PIPELINE.md`'s "Sample QC: signal/coverage funnel" section for the full numbers. Two explanations are possible and not mutually exclusive:

1. The unmapped >99% is genuine non-target DNA (environmental/microbial contamination — expected for a shipwreck-recovered sample sequenced without target enrichment).
2. Some of it is real *Coffea* DNA that failed to align for methodological reasons (alignment stringency, reference completeness, etc.) — i.e. we're throwing away real signal.

Rather than assume either answer, this repo taxonomically classifies a random subsample of the off-target reads with Kraken2 to find out directly. A raw-read %GC mismatch (61% in the reads vs. ~37.5% in the reference) already hints at bacterial contamination, but that's circumstantial — this is the direct check.

## What the result tells us

- **Dominated by marine/soil/environmental bacterial taxa** → confirms contamination, the alignment step excluded it correctly, no signal lost.
- **A meaningful fraction lands in Rubiaceae/*Coffea*-adjacent taxa**, or a large "unclassified" fraction with characteristics consistent with plant DNA → real signal is being missed, and `the_coffee_wrecks/bwa-vrouw.sh`'s alignment parameters (or reference choice) likely need revisiting — see that repo's "bwa aln parameters" section in `PIPELINE.md` for the current settings and their literature basis.

## Pipeline

1. `download_kraken2_db.sh` — one-time download of the Kraken2 PlusPF-8 database (~5.5GB compressed, ~7.5GB extracted). Run directly on the login node.
2. `subsample_unmapped.sh <SAMPLE>` — pulls a random subsample (default 2,000,000 reads) of off-target reads per sample. Two modes, chosen automatically: precise (true unmapped reads, via `samtools view -f 4`) where `the_coffee_wrecks/bwa-out/${SAMPLE}_sorted.bam` still exists (R0003, R0004 as of 2026-09), or approximate (raw-fastq subsample, statistically equivalent given <1% mapping rate) where it's been cleaned up (R0002, R0005).
3. `run_kraken2.sh <SAMPLE>` — classifies the subsample, writes a standard Kraken2 report (`results/${SAMPLE}/${SAMPLE}_kraken2_report.txt`) plus per-read classifications.
4. `run_screening.sh [SAMPLE...]` — orchestrates 2–3 as an sbatch dependency chain per sample (mirrors `the_coffee_wrecks/run_pipeline.sh`'s pattern), defaults to all 4 samples if none given.

```bash
./download_kraken2_db.sh        # once
./run_screening.sh              # all 4 samples, or list specific ones
squeue -u $USER                 # check status
```

## Storage

`kraken2_db/` and `results/` are gitignored (generated data, same convention as `the_coffee_wrecks`). Both live only on Roihu's `/scratch` — nothing here is archived to Allas yet.
