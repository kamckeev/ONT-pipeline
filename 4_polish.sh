#!/bin/bash
#BSUB -n 16
#BSUB -J polish_A_r4
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J
#BSUB -W 500
#BSUB -R rusage[mem=40GB]
#BSUB -R span[hosts=1]

THREADS=16
NAME="SampleA_r4"

#Name directories
MAIN_DIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs"

#use the unzipped "porechop.chopped.fastq" that was produced in 2, but converted in 3_assembly.sh
INPUT_FASTQ="${MAIN_DIR}/2_TRIM_data/SampleA_good/SampleA.pass.porechop.chopped.fastq"

#This file also takes the assembly produced in step 3
#ASSEMBLY="${MAIN_DIR}/3_assembly/SampleB_good/hifi_v2/HiFiasm_B_v2_assembly.p_ctg.fa"

#or a previously polished assembly to try to improve again
ASSEMBLY="${MAIN_DIR}/4_polishing/SampleA_good/SampleA_r3.p_ctg.polished.fasta"
####################################
OUT_DIR="${MAIN_DIR}/4_polishing/SampleA_good"
#mkdir -p "$OUT_DIR"

# Define a shared directory for mapping.paf
MAPPING_FILE="${OUT_DIR}/mapping.paf"

# Polished assembly output (to be produced by Racon)
POLISHED_ASSEMBLY="${OUT_DIR}/${NAME}.p_ctg.polished.fasta"

############################3
# Check if the input file is gzipped (ends with .gz); if so, unzip it.
if [[ "$INPUT_FASTQ" == *.gz ]]; then
    echo "Input file is gzipped. Unzipping..."
    # Unzip to the same directory with the .gz extension removed
    gunzip -c "$INPUT_FASTQ" > "${INPUT_FASTQ%.gz}"
    # Update the input file variable to point to the unzipped file
    INPUT_FASTQ="${INPUT_FASTQ%.gz}"
    echo "Unzipping complete. Using unzipped file: $INPUT_FASTQ"
fi

######################################
# Map reads to assembly with minimap2
echo "minimap2 start..."
(
  cd "/rs1/researchers/c/ccgoller/wwconsulting/minimap2" 
  eval "$(pixi shell-hook)"

  echo "Mapping  reads to assembly using minimap2..."
  minimap2 -t $THREADS -x map-ont "$ASSEMBLY" "$INPUT_FASTQ" > "$MAPPING_FILE"

  if [ $? -ne 0 ]; then
      echo "Error during minimap2 mapping."
      exit 1
  fi
)
echo "minimap2end"
######################################
# Polish assembly with Racon
echo "Activating Racon..."
(
cd "/rs1/researchers/c/ccgoller/wwconsulting/Racon" 
eval "$(pixi shell-hook)"

echo "Running Racon polishing..."
racon -t $THREADS "$INPUT_FASTQ" "$MAPPING_FILE" "$ASSEMBLY" > "$POLISHED_ASSEMBLY"

if [ $? -ne 0 ]; then
    echo "Error during Racon polishing."
    exit 1
fi
)
echo "Racon End"
echo "run completed"