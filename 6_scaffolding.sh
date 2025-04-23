#!/bin/bash
#BSUB -n 4
#BSUB -J Ragtag_TidkB
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J
#BSUB -W 180
#BSUB -R rusage[mem=16GB]
#BSUB -R span[hosts=1]

#########################################
# Define input and output file paths
#########################################

# Input draft assembly (prior to scaffolding)
DRAFT_ASSEMBLY="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/3_assembly/SampleB_raw/SampleB_raw.p_ctg.fa"

# Reference assembly used by RagTag for scaffolding
REFERENCE_ASSEMBLY="/rs1/researchers/c/ccgoller/epi2me/waxworm_reference_genome/GCF_026898425_CSIRO_AGI_GalMel_v1_genomic.fasta"

# Output directory for RagTag scaffolding results
RAGTAG_OUT="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/6_scaffolding/SampleB"
mkdir -p "$RAGTAG_OUT"

# Output file for Tidk telomere detection results
TIDK_OUT="telomeres"

SCAFFOLDED_ASSEMBLY="${RAGTAG_OUT}/ragtag.scaffold.fasta"

#########################################
# Step 1: Run RagTag Scaffolding
#########################################
echo "Running RagTag scaffolding..."
cd "/rs1/researchers/c/ccgoller/wwconsulting/ragtag"  # Change to RagTag installation directory if needed
(
    # Activate the RagTag Pixi environment
    eval "$(pixi shell-hook)"

    # Run RagTag; adjust parameters as needed
    ragtag.py scaffold "$REFERENCE_ASSEMBLY" "$DRAFT_ASSEMBLY" -o "$RAGTAG_OUT"
)

# (Optional) Verify that the scaffolded assembly was produced.
SCAFFOLDED_ASSEMBLY="${RAGTAG_OUT}/ragtag.scaffold.fasta"
if [ ! -f "$SCAFFOLDED_ASSEMBLY" ]; then
    echo "Error: Scaffolded assembly not found at $SCAFFOLDED_ASSEMBLY"
    exit 1
fi
echo "RagTag scaffolding completed. Scaffolded assembly: $SCAFFOLDED_ASSEMBLY"

#########################################
# Step 2: Run Tidk for Telomere Detection
#########################################
echo "Running Tidk for telomere detection..."
cd "/rs1/researchers/c/ccgoller/wwconsulting/tidk"  # Change to Tidk installation directory if needed
(
    # Activate the Tidk Pixi environment
    eval "$(pixi shell-hook)"
    
    mkdir -p ~/.tidk
    cp /rs1/researchers/c/ccgoller/wwconsulting/tidk/curated.csv ~/.tidk/curated.csv

    # Run Tidk to locate telomeres; set with most common teleomere repeat in phylum Lepidoptera, also used in BUSCO assessment
    tidk search --string "AACCT" --output "$TIDK_OUT" --dir "$RAGTAG_OUT" "$SCAFFOLDED_ASSEMBLY"
    
    # Generate Tidk plots, grouped by chromosome/scaffold
    tidk plot --tsv "${RAGTAG_OUT}/${TIDK_OUT}_telomeric_repeat_windows.tsv" \
          -o "${RAGTAG_OUT}/${TIDK_OUT}_telomeric_repeat_windows" 

)
echo "Tidk telomere detection completed. Results written to $RAGTAG_OUT"

#########################################
# Pipeline Completion
#########################################
echo "Pipeline completed. Check the output directories for RagTag scaffolds and Tidk telomere results."

exit