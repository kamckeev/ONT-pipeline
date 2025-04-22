#!/bin/bash
#BSUB -J QC_postA
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J
#BSUB -W 120
#BSUB -n 16
#BSUB -R rusage[mem=32GB]
#BSUB -R span[hosts=1]

######################################
# Job script to run assembly_stats, BUSCO, and QUAST on an assembly

THREADS=16

# Define the  output directory and subdirectories for each tool.
MAIN_DIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs"
ASSEMBLY="${MAIN_DIR}/4_polishing/SampleA_2/HiFiasm_A_v2_assembly.bp.p_ctg.polished.fasta"

QC_POST="${MAIN_DIR}/5_QC_post/SampleA/polished"
QUAST_OUT="$QC_POST/quast"
STATS_OUT="$QC_POST/assembly_stats"

# Create output directories 
mkdir -p "$QUAST_OUT" "$STATS_OUT"

######################################
# Define the input assembly file.
# You can use a gzipped assembly file or an unzipped file.
#convert Hifiasm assembly if needed, so that Racon can polish
#ASSEMBLY=
#awk '/^S/{print ">"$2"\n"$3}' "$ASSEMBLY" > "$QC_POST/HiFiasm_B_v2_assembly.bp.hap1.p_ctg.fa"

#If the assembly was unzipped, redefine input assembly here, that was created following unzipping
#ASSEMBLY=

# Check if the assembly file exists
if [ ! -f "$ASSEMBLY" ]; then
    echo "Error: Assembly file '$ASSEMBLY' not found!"
    exit 1
fi

echo "Assembly file to be analyzed: $ASSEMBLY"

######################################
# Run assembly_stats
echo "Running assembly_stats analysis..."

cd "/rs1/researchers/c/ccgoller/wwconsulting/assembly-stats"
(
eval "$(pixi shell-hook)"

assembly-stats "$ASSEMBLY" > "$STATS_OUT/assembly_stats_ref.txt"
)

echo "assembly_stats analysis complete. Output saved to $STATS_OUT/assembly_stats_ref.txt"

######################################
# BUSCO analysis
echo "Running BUSCO analysis..."

cd "/rs1/researchers/c/ccgoller/wwconsulting/busco"
(
eval "$(pixi shell-hook)"

# Force BUSCO to skip update and work in offline mode.
  export BUSCO_SKIP_UPDATE=True
  busco -i "$ASSEMBLY" \
        -l "/rs1/researchers/c/ccgoller/wwconsulting/busco/busco_downloads/lineages/lepidoptera_odb10" \
        -o busco_results \
        -m genome \
        -c 4 \
        --out_path "$QC_POST" \
        --offline \
	-f
      
echo "BUSCO analysis complete. Check output in $QC_POST"
)
######################################
# QUAST 

echo "Running QUAST analysis..."

cd "/rs1/researchers/c/ccgoller/wwconsulting/quast"
(
eval "$(pixi shell-hook)"

quast.py -t "$THREADS" -o "$QUAST_OUT" "$ASSEMBLY"
)
echo "QUAST analysis complete. Check output in $QUAST_OUT"

echo "All analyses are complete."
