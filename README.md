# ONT-pipeline
Pipeline for assembling or rebasecalling raw Oxford nanopore reads

The pipeline is comprised of 8 scripts following 8 steps of genome assembly. Scripts are depositid here on git hub as well as on Dr. Goller's space on NCSU Hazel cluster. The pipeline begins with converting the output of the dorado basecalling in Epi2me into a fastq file.

In general, all user defined variables which may change between different datasets are defined in all caps (ex: OUTPUT_FASTQ_DIR) and later references in the script (ex: "$OUTPUT_FASTQ_DIR"). Users should only change the directory paths to identify their specific dataset at the beginning of the script to avoid creating errors. For ease of use there is a comment line which states "No editing belwo this point". Some software includes variables specific to the software (ex: read depth of data), which the user may wish to alter for their specific dataset.  Specific programs are called in a pixi environment, where each program has a folder within the project folder (wwconsulting).  

## 1_QC_preassembly.sh
 - what it does: converst the cram file from the dorado basecaller (PASS_CRAM) to a fastq file. Runs Kraken2 to detect and remove contamination using a database. Runs Nanoplot to map read length and quality metrics. Runs KMC to count number of unique k-mers (set to 17 by -k17 in script). Puts all cleaned sequences and diagnostic plots into software specific folders in OUTPUT_DIR.
 - input variables
     - NAME Name of the sample; used to construct paths dynamically. If multiple samples were run for the same project, can be seperated within the output directory. 
         - example value: "SampleA"
     - KRACKEN2_DB Path to the Kraken2 database directory used for classification.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_pluspf_08gb_20241228
     - PASS_CRAM Path to the input CRAM file (used for FASTQ conversion).
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/{$NAME}/no_reference/SAMPLE.pass.cram
     - OUTPUT_FASTQ_DIR Directory where the converted FASTQ file will be saved.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads
     - INPUT_FASTQ Path to the resulting FASTQ file after CRAM conversion.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/SAMPLE_A.pass.fastq
     - OUTPUT_DIR Root output directory for all downstream tools (Kraken2, NanoPlot, KMC).
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads
     - KRACKEN2_OUT Output directory for Kraken2 results.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/kraken2/SampleA
     - NANOPLOT_OUT Output directory for NanoPlot results.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/nanoplot/SampleA
     - KMC_OUT Output directory for KMC results.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/kmc/SampleA
     - KMC_TMP Temporary directory for KMC processing.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/1_QC_pre/SampleA/raw_reads/kmc/SampleA/tmp

 
## 2_trim_reads.sh
- what it does: use
- input variables
     - PASS_CRAM Path to the CRAM file used as the input for conversion to FASTQ.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/SampleA/no_reference/SAMPLE.pass.cram
     - ref Path to the reference genome used during CRAM to FASTQ conversion (commented out)
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/GCF_026898425_CSIRO_AGI_GalMel_v1_genomic.fasta
     - OUTPUT_FASTQ_DIR Directory where the converted FASTQ file will be saved.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference
     - FASTQ_FILE Path to the resulting FASTQ file after CRAM conversion.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A.pass.fastq
     - PORECHOP_OUTPUT_DIR Directory for output from Porechop trimming.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference
     - PORECHOP_OUTFILE Path to the Porechop-trimmed FASTQ file.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A.pass.porechop.fastq
     - CHOPPER_OUTPUT_DIR Directory for output from Chopper trimming.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference
     - CHOPPER_OUTFILE Final output FASTQ file after both Porechop and Chopper steps.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A_v2.pass.porechop.chopped.fastq.gz
- User-defined settings
     - Chopper
          - minimum quality score to trim reads (-q 17)
          - minimum read length to filter reads (-l 800)
          - number of threads to run program on (-- threads 16), do not change unless running on a different server
          - number of base pairs to trim off start of all reads (--headcrop 10)
          - number of base pairs to trim of end of all reads (--tailcrop 10)

## 3_hifiasm_assembly.sh

## 5_QC_post.sh

## 6_mummer.sh

## 7_scaffolding.sh

## 8_annotation.sh
