#!/bin/bash
#BSUB -J hifi_B                  # Job name
#BSUB -n 16                       # Total cores
#BSUB -R "span[hosts=1]"          # All cores on one node
#BSUB -R "rusage[mem=10GB]"       # 10 GB RAM per core → 32×10 GB = 320 GB total
#BSUB -M 10GB                     # Enforce 10 GB/core
#BSUB -W 500                      # Wall time, in minutes
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J

set -e
ulimit -s unlimited

# This script runs hifiasm on trimmed Oxford Nanopore reads and purges haplotig duplicates.
# All output files will be stored in the specified output directory.

# Number of threads to use (adjust as needed, needs to match "#BSUB -n" at top)
THREADS=16
NAME="ABnoK"

##########################
# This script uses an already filtered and trimmed FASTQ file.
# It checks whether the file is gzipped and, if so, unzips it.
MAIN_DIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs"

# Set the directory for output
OUTPUT_DIR="${MAIN_DIR}/3_assembly/${NAME}"
mkdir -p "$OUTPUT_DIR"

# Input FASTQ file (already trimmed and adaptor removed)
#can be gzipped or unzipped, code checks

INPUT_FASTQ="${MAIN_DIR}/3_assembly/ABnoKraken.fastq"
#"${MAIN_DIR}/2_TRIM_data/SampleB_raw2_ALtest/SampleB_raw2_ALtest.pass.porechop.chopped.fastq"
#"${MAIN_DIR}/2_TRIM_data/SampleA_raw/SampleA_raw.pass.porechop.chopped.fastq"

##################################
#No edititing below
##################################

##########################
# Check if the input file is gzipped (ends with .gz); if so, unzip it.
if [[ "$INPUT_FASTQ" == *.gz ]]; then
    echo "Input file is gzipped. Unzipping..."
    # Unzip to the same directory with the .gz extension removed
    gunzip -c "$INPUT_FASTQ" > "${INPUT_FASTQ%.gz}"
    # Update the input file variable to point to the unzipped file
    INPUT_FASTQ="${INPUT_FASTQ%.gz}"
    echo "Unzipping complete. Using unzipped file: $INPUT_FASTQ"
fi

##########################
#hifiasm assembler for ONT

echo "Running hifiasm on $INPUT_FASTQ..."
(
cd "/rs1/researchers/c/ccgoller/wwconsulting/hifiasm"
eval "$(pixi shell-hook)"

# Run hifiasm in Oxford Nanopore mode
hifiasm -o "$OUTPUT_DIR/${NAME}" --ont -t $THREADS "$INPUT_FASTQ"

# Check if hifiasm finished successfully
if [ $? -ne 0 ]; then
    echo "hifiasm failed. Exiting."
    exit 1
fi)

# Convert the primary contig GFA to FASTA for downstream processing.
echo "Converting primary contigs from GFA to FASTA..."
awk '/^S/{print ">"$2"\n"$3}' "$OUTPUT_DIR/${NAME}.bp.p_ctg.gfa" > "$OUTPUT_DIR/${NAME}.p_ctg.fa"

# The primary contigs file is created as ${NAME}.p_ctg.fa in $OUTPUT_DIR.
ASSEMBLY="$OUTPUT_DIR/${NAME}.p_ctg.fa"
