#!/bin/bash
#BSUB -J mumA_ref
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J
#BSUB -n 16
#BSUB -R rusage[mem=20GB]
#BSUB -R span[hosts=1]
#BSUB -W 200

#what are you calling your run/files?
NAME="scaffoldsA_vs_ref_100k"
THREADS=16


# Inputs
REF="/rs1/researchers/c/ccgoller/epi2me/waxworm_reference_genome/GCF_026898425_CSIRO_AGI_GalMel_v1_genomic.fasta"

QUERY="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/6_scaffolding/SampleA_good/ragtag.scaffold.fasta"
#REF="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/6_scaffolding/SampleB_good/ragtag.scaffold.fasta"

OUTDIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/7_alignment/mummer/${NAME}"
mkdir -p "$OUTDIR"

PREFIX="${OUTDIR}/${NAME}"


# Activate your Pixi environment (edit path if needed)
cd "/rs1/researchers/c/ccgoller/wwconsulting/mummer"
eval "$(pixi shell-hook)"

#load gnuplot for plotting assistance
module load gnuplot

# Run nucmer
nucmer --prefix=$PREFIX "$REF" "$QUERY"

# Filter alignments with length >= 10000 and identity >= 98%
delta-filter -l 100000 -i 98 ${PREFIX}.delta > ${PREFIX}.filtered.delta

# Generate mummerplot (ensure gnuplot is available in the Pixi env)
mummerplot --fat --filter --layout --png --prefix=$PREFIX ${PREFIX}.filtered.delta
