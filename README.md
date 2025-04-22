# ONT-pipeline
Pipeline for assembling or rebasecalling raw Oxford nanopore reads

The pipeline is comprised of 8 scripts following 8 steps of genome assembly. Scripts are depositid here on git hub as well as on Dr. Goller's space on NCSU Hazel cluster. The pipeline begins with converting the output of the dorado basecalling in Epi2me into a fastq file.

In general, all user defined variables which may change between different datasets are defined in all caps (ex: OUTPUT_FASTQ_DIR) and later references in the script (ex: "$OUTPUT_FASTQ_DIR"). Users should only change the directory paths to identify their specific dataset at the beginning of the script to avoid creating errors. For ease of use there is a comment line which states "No editing belwo this point". Some software includes variables specific to the software (ex: read depth of data), which the user may wish to alter for their specific dataset.  Specific programs are called in a pixi environment, where each program has a folder within the project folder (wwconsulting).  

## 1_QC_preassembly.sh
 - what it does: Runs Kraken2 to detect and remove contamination using a database. Runs Nanoplot to map read length and quality metrics. Runs KMC to count number of unique k-mers (set to 17 by -k17 in script). Puts all cleaned sequences and diagnostic plots into software specific folders in OUTPUT_DIR.
 - input variables
     - NAME Name of the sample; used to construct paths dynamically. If multiple samples were run for the same project, can be seperated within the output directory. 
         - example value: "SampleA"
     - THREADS number of threads to use for multi-threading tool Must match #BSUB -n
         - example value: 32
     - KMER K-mer size to use for k-mer counting in KMC.
         - example value: 17
     - KRACKEN2_DB Path to the Kraken2 database directory used for classification. 
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/kraken2/DBs/k2_pluspf_08gb_20241228
     - MAIN_DIR Directory where pipeline outputs are saved.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs
     - PASS_CRAM Path to the input CRAM file (used for FASTQ conversion).
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/basecalled_data/{$NAME}/no_reference/SAMPLE.pass.cram
     - OUTPUT_DIR likely wont' change, named directory in MAIN_DIR where outputs are saved
         - example value: "${MAIN_DIR}/1_QC_pre/${NAME}"
     - USE_REF Flag to determine whether to use a reference genome during CRAM to FASTQ conversion.
         - example value: 0 (use reference) or 1 (don’t use reference)
     - ref Path to the reference genome used in CRAM to FASTQ conversion (required if USE_REF=0).
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/references/hg38.fal
 
## 2_trim_reads.sh
- what it does: use porechop to identify adapters and trim the from reads, and then use chopper to trim reads based on quality and other parameters
- input variables
     - NAME Name of the sample; used to construct output filenames and directories for this trimming step.
          - example value: "SampleB_raw"
     - THREADS Number of threads to use for parallel processing in tools like Porechop and Chopper. Must match #BSUB -n
       - example value: 16
     - MAIN_DIR Root output directory where all pipeline results will be saved.
       - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs
     - FASTQ_FILE Path to the resulting FASTQ file after CRAM conversion.
       - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A.pass.fastq
     - PHRED Minimum Phred quality score required to keep a read during trimming with Chopper.
       - example value: 17
     - MIN_LENGTH Minimum read length (in bases) required to keep a read after trimming.
       - example value: 800
     - HEAD Number of bases to trim from the start (5' end) of each read.
       - example value: 10
     - TAIL Number of bases to trim from the end (3' end) of each read.
       - example value: 10
     - PC_THRESH Adapter match threshold used by Porechop to determine whether to trim an adapter; lower values make trimming more permissive. Keep at 90 unless good reason to change, beware of false positives
        -example value: 90.0
     - PORECHOP_OUTPUT_DIR Directory for output from Porechop trimming.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference
     - PORECHOP_OUTFILE Path to the Porechop-trimmed FASTQ file.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A.pass.porechop.fastq
     - CHOPPER_OUTPUT_DIR Directory for output from Chopper trimming.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference
     - CHOPPER_OUTFILE Final output FASTQ file after both Porechop and Chopper steps.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A_v2.pass.porechop.chopped.fastq.gz

## 3_hifiasm_assembly.sh
- what it does: Uses hifiasm to assemble fasta sequences into contigs
- Input Variables:
      - NAME Name of the sample; used to build paths for both input and output files.
           - example value: "SampleA_raw"
      - THREADS Number of CPU threads used during hifiasm assembly; should match the scheduler directive (#BSUB -n).
           - example value: 16
      - MAIN_DIR Base directory where all outputs and intermediate results are stored.
           - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs
      - OUTPUT_DIR Target directory for the assembled genome and intermediate files. This is derived from MAIN_DIR and NAME.
           - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/3_assembly/SampleA_raw
      - INPUT_FASTQ Path to the final trimmed, filtered, and adapter-removed FASTQ file. Can be gzipped (.fastq.gz) or uncompressed.
           - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA_raw/SampleA_raw.pass.porechop.chopped.fastq.gz
## 5_QC_post.sh
- what it does: Asseses quality of hifi assembly using assembly stats, BUSCO and QUAST
- Input Variables:
      - THREADS Number of threads used for multithreaded tools like quast, must match #BSUB -n
           - example value: 16
      - MAIN_DIR Root directory for all input/output subfolders in this workflow.
           - example: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs
      - ASSEMBLY Path to the final polished genome assembly file used for QC analysis.
           - example: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/4_polishing/SampleA_2/HiFiasm_A_v2_assembly.bp.p_ctg.polished.fasta
      - QC_POST Parent output directory for all QC tools' results. 
           - example: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/5_QC_post/SampleA/polished
      - QUAST_OUT Output directory for QUAST results.
           - example: $QC_POST/quast
      - STATS_OUT Output directory for assembly-stats results.
           - example: $QC_POST/assembly_stats
## 6_mummer.sh

## 7_scaffolding.sh

## 8_annotation.sh
