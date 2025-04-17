# ONT-pipeline
Pipeline for assembling or rebasecalling raw Oxford nanopore reads

The pipeline is comprised of 8 scripts following 8 steps of genome assembly. Scripts are depositid here on git hub as well as on Dr. Goller's space on NCSU Hazel cluster. In general, all user defined variables which may change between different datasets are defined in all caps (ex: OUTPUT_FASTQ_DIR) and later references in the script (ex: "$OUTPUT_FASTQ_DIR"). Users should only change the directory paths to identify their specific dataset at the beginning of the script to avoid creating errors. Some software includes variables specific to the software (ex: read depth of data), which the user may wish to alter for their specific dataset. 

## 1_QC_preassembly.sh
 - input variables
     - NAME Name of the sample; used to construct paths dynamically.
         - Current value: "SampleA"

KRACKEN2_DB
Path to the Kraken2 database directory used for classification.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_pluspf_08gb_20241228

KRACKEN2_ARCHIVE (commented out)
Archive file to extract the Kraken2 database if it's not already extracted.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_viral_20241228.tar.gz

PASS_CRAM
Path to the input CRAM file (used for FASTQ conversion).
Current value: /rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/{$NAME}/no_reference/SAMPLE.pass.cram

ref (commented out)
Optional path to a reference genome for CRAM conversion (uncomment to use).
Current value: /rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/GCF_026898425_CSIRO_AGI_GalMel_v1_genomic.fasta

OUTPUT_FASTQ_DIR
Directory where the converted FASTQ file will be saved.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads

INPUT_FASTQ
Path to the resulting FASTQ file after CRAM conversion.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/SAMPLE_A.pass.fastq

OUTPUT_DIR
Root output directory for all downstream tools (Kraken2, NanoPlot, KMC).
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads

KRACKEN2_OUT
Output directory for Kraken2 results.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/kraken2/SampleA

NANOPLOT_OUT
Output directory for NanoPlot results.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/nanoplot/SampleA

KMC_OUT
Output directory for KMC results.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/kmc/SampleA

KMC_TMP
Temporary directory for KMC processing.
Current value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/kmc/SampleA/tmp
## 2_trim_reads.sh

## 3_hifiasm_assembly.sh

## 5_QC_post.sh

## 6_mummer.sh

## 7_scaffolding.sh

## 8_annotation.sh
