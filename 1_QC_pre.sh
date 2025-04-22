#!/bin/bash
#BSUB -n 32
#BSUB -J QC_B
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J
#BSUB -W 500
#BSUB -R rusage[mem=32GB]
#BSUB -R span[hosts=1]

NAME="SampleB"
THREADS=32
KMER=17

# Define absolute paths for the input FASTQ file and Kraken2 database
#KRACKEN2_ARCHIVE="/rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_viral_20241228.tar.gz"

#############options that are already unzipped##############
###STANDARD LIMITED TO 8GB
KRACKEN2_DB="/rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_pluspf_08gb_20241228"

###STANDARD LIMITED TO 16GB
#KRACKEN2_DB="/rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_standard_16gb_20241228"

###VIRAL DATA (SMALLEST DB)
#KRACKEN2_DB="/rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_viral_20241228"


# Check if the Kraken2 DB directory exists; if not, untar the archive
if [ ! -d "$KRACKEN2_DB" ]; then
    echo "Kraken2 database directory not found. Extracting from archive..."
    tar -xzvf "$KRACKEN2_ARCHIVE" -C "$(dirname "$KRACKEN2_DB")"
fi
#############################################
# Define output directories
MAIN_DIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs"
PASS_CRAM="/rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/SampleB/no_reference/SAMPLE.pass.cram"
OUTPUT_DIR="${MAIN_DIR}/1_QC_pre/${NAME}"
INPUT_FASTQ="${OUTPUT_DIR}/${NAME}.pass.fastq"

KRACKEN2_OUT="${OUTPUT_DIR}/kraken2"
KR_OUT="${KRACKEN2_OUT}/kraken2_output.txt"
UNCLASS_IDS="${OUTPUT_DIR}/kraken2/unclassified.ids"
FILTERED_FASTQ="${KRACKEN2_OUT}/filtered_${NAME}.fastq"

NANOPLOT_OUT="${OUTPUT_DIR}/nanoplot_raw"
NANOPLOT_OUT_filtered="${OUTPUT_DIR}/nanoplot_filtered"

KMC_OUT="${OUTPUT_DIR}/kmc_raw"
KMC_TMP="${KMC_OUT}/tmp"
KMC_OUT_filtered="${OUTPUT_DIR}/kmc_filtered"
KMC_TMP_filtered="${KMC_OUT_filtered}/tmp"

# Create all directories
mkdir -p \
  "$OUTPUT_DIR" \
  "$KRACKEN2_OUT" \
  "$(dirname "$KR_OUT")" \
  "$NANOPLOT_OUT" \
  "$NANOPLOT_OUT_filtered" \
  "$KMC_OUT" \
  "$KMC_TMP" \
  "$KMC_OUT_filtered" \
  "$KMC_TMP_filtered"
  
################# Cram conversion
# Cram conversion can be done with or without a reference. 
# USE_REF must be set to "1" if you want to perform reference-based conversion.
(
cd "/rs1/researchers/c/ccgoller/wwconsulting/samtools"
eval "$(pixi shell-hook)"

#USE_REF LINE
if [ "$USE_REF" = "0" ]; then
    if [ ! -f "${ref}.fai" ]; then
        echo "Indexing the reference..."
        pixi run samtools faidx "$ref"
    fi
    echo "Converting PASS reads WITH reference..."
    pixi run samtools fastq -T "$ref" "$PASS_CRAM" > "$INPUT_FASTQ"
else
    echo "Converting PASS reads WITHOUT reference..."
    pixi run samtools fastq "$PASS_CRAM" > "$INPUT_FASTQ"
fi)
##################################################################################
#No editing below this point
##################################################################################

################# Kraken2
cd "/rs1/researchers/c/ccgoller/wwconsulting/kraken2"
(
  eval "$(pixi shell-hook)"

  echo "Running Kraken2 ($THREADS threads)…"
    kraken2 \
    --threads $THREADS \
    --db      "$KRACKEN2_DB" \
    --output  "$KR_OUT" \
    --report  "${KRACKEN2_OUT}/kraken2_report.txt" \
    "$INPUT_FASTQ"

  echo "Extracting unclassified IDs…"
  awk '$1=="U" {print $2}' "$KR_OUT" > "$UNCLASS_IDS"

  echo "Re-extracting unclassified FASTQ…"
 )
 ############ seqtk filter
(cd "/rs1/researchers/c/ccgoller/wwconsulting/seqtk"
   eval "$(pixi shell-hook)"
 
  seqtk subseq "$INPUT_FASTQ" "$UNCLASS_IDS" > "$FILTERED_FASTQ"
  if [ ! -s "$FILTERED_FASTQ" ]; then
    echo "WARNING: No unclassified reads found." >&2
  fi
)
################ Nanoplot
cd "/rs1/researchers/c/ccgoller/wwconsulting/nanoplot"
(
  eval "$(pixi shell-hook)"

  echo "NanoPlot (raw)…"
  NanoPlot --threads $THREADS --fastq "$INPUT_FASTQ"       --outdir "$NANOPLOT_OUT"
  echo "NanoPlot (filtered)…"
  NanoPlot --threads $THREADS --fastq "$FILTERED_FASTQ"   --outdir "$NANOPLOT_OUT_filtered"
)

################ KMC
# Run KMC for k-mer counting 

#load gnuplot for histogram
module load gnuplot

cd "/rs1/researchers/c/ccgoller/wwconsulting/kmc"
(
eval "$(pixi shell-hook)"

echo "Running KMC (raw)..."
kmc -k$KMER -t$THREADS "$INPUT_FASTQ" "${KMC_OUT}/kmc_output" "$KMC_TMP"

echo "Dumping KMC binary file to text..."
# Dump k-mer counts (each line: <k-mer> <count>)
kmc_tools transform "${KMC_OUT}/kmc_output" dump "${KMC_OUT}/kmc_dump.txt"

echo "Generating histogram data using awk..."
# Process the dump file to create a histogram: for each count value, count how many k-mers have that frequency.
awk '{hist[$2]++} END {for (i in hist) print i, hist[i]}' "${KMC_OUT}/kmc_dump.txt" | sort -n > "${KMC_OUT}/kmc_histogram.txt"

echo "Plotting histogram with gnuplot..."
# Ensure gnuplot is installed and in your PATH (or load it with a module command if required)
gnuplot -e "set terminal png size 800,600; \
set output '${KMC_OUT}/kmc_histogram.png'; \
set title 'K-mer Histogram'; \
set xlabel 'K-mer frequency'; \
set ylabel 'Count'; \
plot '${KMC_OUT}/kmc_histogram.txt' using 1:2 with boxes notitle"
)

#########
(
  eval "$(pixi shell-hook)"
  echo "Running KMC (unclassified reads)..."
  kmc -k$KMER -t$THREADS "$FILTERED_FASTQ" "${KMC_OUT_filtered}/kmc_output" "$KMC_TMP_filtered"
  echo "Dumping KMC unclassified counts..."
  kmc_tools transform "${KMC_OUT_filtered}/kmc_output" dump "${KMC_OUT_filtered}/kmc_dump.txt"
  awk '{hist[$2]++} END {for (i in hist) print i, hist[i]}' \
    "${KMC_OUT_filtered}/kmc_dump.txt" | sort -n > "${KMC_OUT_filtered}/kmc_histogram.txt"
  gnuplot -e "set terminal png size 800,600; \
    set output '${KMC_OUT_filtered}/kmc_histogram.png'; \
    set title 'Unclassified Reads K-mer Histogram'; \
    set xlabel 'K-mer frequency'; \
    set ylabel 'Count'; \
    plot '${KMC_OUT_filtered}/kmc_histogram.txt' using 1:2 with boxes notitle"
)

echo "Pipeline completed. Check $OUTPUT_DIR for all results."
exit
