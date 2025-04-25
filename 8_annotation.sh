#!/bin/bash
#BSUB -J ann_A
#BSUB -n 32
#BSUB -R "rusage[mem=16G]"
#BSUB -W 3000          
#BSUB -e /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stderr/stderr.%J
#BSUB -o /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/run_info/stdout/stdout.%J

set -euo pipefail

# Global variables for all steps:
ANNO_NAME="SAMPLE_A"

GENOME="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/3_assembly/SampleA_v2/HiFiasm_A_v2_assembly.p_ctg.fa"
THREADS=32
protein_DB="/rs1/researchers/c/ccgoller/wwconsulting/diamond/DBs/GCF_026898425.1/protein.faa"
OUTDIR="/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/8_annotation/${ANNO_NAME}"
mkdir -p "$OUTDIR"

#Adjust path to scratch directory
SCRATCH_DIR="/share/wgsshogun/kamckeev"
mkdir -p "$SCRATCH_DIR"

###############################
# Step 1: Build RepeatModeler DB and Run RepeatModeler
###############################
###############################
echo "Running RepeatModeler..."
(
    # Create a unique temporary directory for this run on scratch.
    SCRATCH_TMP=$(mktemp -d "${SCRATCH_DIR}/run_${USER}_XXXXXX")
    echo "Using temporary scratch directory: $SCRATCH_TMP"

    # Source the Pixi environment for RepeatModeler
    cd "/rs1/researchers/c/ccgoller/wwconsulting/repeatmodeler"
    eval "$(pixi shell-hook)"

    mkdir -p "$OUTDIR/repeatmodeler"

    # Copy the genome file to the temporary directory and work from there.
    cp "$GENOME" "$SCRATCH_TMP/"
    cd "$SCRATCH_TMP"

    # Create a symlink for the genome (named genome.fasta) and run BuildDatabase.
    ln -sf "$(basename "$GENOME")" genome.fasta
    BuildDatabase -name waxworm_db genome.fasta

    # Run RepeatModeler using the created database.
    RepeatModeler -database waxworm_db -threads $THREADS -LTRStruct

    # RepeatModeler creates a dynamically named directory (e.g., RM_XXXXX.*)
    # Find the RM output directory in the temporary workspace.
    RM_DIR=$(find . -maxdepth 1 -type d -name 'RM_*' | sort | tail -n 1)
    if [ -z "$RM_DIR" ]; then
        echo "Error: No RM_* directory found in ${SCRATCH_TMP}" >&2
        exit 1
    fi

    echo "Copying RepeatModeler results from $SCRATCH_TMP/$RM_DIR to $OUTDIR/repeatmodeler/"
    cp -r "$SCRATCH_TMP/$RM_DIR/"* "$OUTDIR/repeatmodeler/"

    # Optionally remove the temporary directory after the results are copied.
    rm -rf "$SCRATCH_TMP"
)
echo "RepeatModeler complete."
###############################
# Step 2: Run RepeatMasker using the RepeatModeler library
###############################
echo "=== Step 2: Running RepeatMasker ==="
(
    cd "/rs1/researchers/c/ccgoller/wwconsulting/repeatmasker"
    eval "$(pixi shell-hook)"
    
    mkdir -p "$OUTDIR/repeatmasker"
    
    # Use the repeat library produced in Step 1. Adjust the path/file name if needed.
    RepeatMasker -pa $THREADS -lib "$OUTDIR/repeatmodeler/consensi.fa" \
        -gff -dir "$OUTDIR/repeatmasker" "$GENOME"
)
echo "RepeatMasker complete."

###############################
# Step 3: Run Funannotate predict on the masked genome.
###############################
# Define the masked genome file produced by RepeatMasker.
MASKED_GENOME="$OUTDIR/repeatmasker/$(basename "$GENOME").masked"

if [ ! -f "$MASKED_GENOME" ]; then
    echo "Error: Masked genome file '$MASKED_GENOME' not found!" >&2
    exit 1
fi

echo "Renaming headers in masked genome file: $MASKED_GENOME"
awk 'BEGIN { i=0; OFS="\t" }
     /^>/ {
         i++;
         newID = sprintf("seq%05d", i);
         print newID, substr($0,2) >> "${OUTDIR}/mapping.txt";
         print ">" newID;
         next
     }
     { print }' "$MASKED_GENOME" > "${OUTDIR}/output.fna"
     
echo "Renaming complete. New file: ${OUTDIR}/output.fna"
echo "Mapping file saved as: mapping.txt"

echo "Running Funannotate predict..."
MASK_SHORT="${OUTDIR}/output.fna"

# Change to the Funannotate installation directory.
(cd "/rs1/researchers/c/ccgoller/wwconsulting/funannotate"

# Pre-export ADDR2LINE to prevent unbound variable errors, then load Pixi environment.
set +u
export ADDR2LINE=/usr/bin/addr2line
eval "$(pixi shell-hook)"
set -u

# Set FUNANNOTATE_DB so funannotate can locate its databases.
export FUNANNOTATE_DB="/rs1/researchers/c/ccgoller/wwconsulting/funannotate/DBs"

mkdir -p "$OUTDIR/funannotate"

# Run funannotate predict using the masked (and header-renamed) genome.
funannotate predict \
    -i "$MASK_SHORT" \
    -o "$OUTDIR/funannotate" \
    --species "Waxworm" \
    --cpus $THREADS \
    --augustus_species fly \
    --busco_seed_species fly \
    --protein_evidence "$protein_DB"
)
echo "Funannotate predict complete!"

echo "=== Combined Pipeline Complete ==="
