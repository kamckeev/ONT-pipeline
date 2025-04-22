#!/bin/bash
#BSUB -J trim_B                 # Job name
#BSUB -n 16                     # Number of cores (adjust if needed)
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J
#BSUB -W 500
#BSUB -R rusage[mem=32GB]
#BSUB -R span[hosts=1]

# Exit immediately if any command exits with a non-zero status
set -e

NAME="SampleB_raw"
THREADS=16

MAIN_DIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs"
OUT_DIR="${MAIN_DIR}/2_TRIM_data/${NAME}"
mkdir -p "$OUT_DIR"

FASTQ_FILE="${MAIN_DIR}/1_QC_pre/SampleB/SampleB.pass.fastq"

# Name the output to reflect that porechop was run on the converted FASTQ file
PORECHOP_OUTFILE="${OUT_DIR}/${NAME}.pass.porechop.fastq"

# Name the final output to indicate both porechop and chopper were applied
CHOPPER_OUTFILE="${OUT_DIR}/${NAME}.pass.porechop.chopped.fastq.gz"

##############################
#EDIT FOR TRIM AND FILTER SETTINGS
#This is where you alter the conditions you want to filter on
#Mininum Phred quality score to include
PHRED=17

#minimum length to include
MIN_LENGTH=800

#how much from the front of the read do you want to remove?
HEAD=10
#How much from the back of the read do you want to remove?
TAIL=10

# Porechop datapter match threhold. Default is 90.0, but may need to lower
#check the out file to see if no adapters were removed because threshold wasn't met
PC_THRESH=90.0

########################################
#No edits below
##########################################
# Run porechop

echo "Running porechop..."
(
cd "/rs1/researchers/c/ccgoller/wwconsulting/porechop"
eval "$(pixi shell-hook)"

porechop -i "${FASTQ_FILE}" -o "${PORECHOP_OUTFILE}" --threads "${THREADS}" --adapter_threshold "${PC_THRESH}"
)
echo "Porechop processing complete: ${PORECHOP_OUTFILE}"

########################################
# Run chopper

echo "Running chopper..."
(
cd "/rs1/researchers/c/ccgoller/wwconsulting/chopper"
eval "$(pixi shell-hook)"

chopper -q "$PHRED" -l "$MIN_LENGTH" --threads "$THREADS" --headcrop "$HEAD" --tailcrop "$TAIL" -i "$PORECHOP_OUTFILE" | gzip > "$CHOPPER_OUTFILE"
)
echo "Chopper processing complete: $CHOPPER_OUTFILE"

echo "Pipeline complete!"
