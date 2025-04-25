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
     - PORECHOP_OUTFILE Path to the Porechop-trimmed FASTQ file.
       - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A.pass.porechop.fastq
     - CHOPPER_OUTFILE Final output FASTQ file after both Porechop and Chopper steps.
       - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/2_TRIM_data/SampleA/no_reference/SAMPLE_A_v2.pass.porechop.chopped.fastq.gz
     - PHRED Minimum Phred quality score required to keep a read during trimming with Chopper.
       - example value: 17
     - MIN_LENGTH Minimum read length (in bases) required to keep a read after trimming.
       - example value: 800
     - HEAD Number of bases to trim from the start (5' end) of each read.
       - example value: 10
     - TAIL Number of bases to trim from the end (3' end) of each read.
       - example value: 10
     - PC_THRESH Adapter match threshold used by Porechop to determine whether to trim an adapter; lower values make trimming more permissive. Keep at 90 unless good reason to change, beware of false positives
       - example value: 90.0
     

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

## 4_polish.sh
- what it does: Uses reads to correct or "polish" an assembly 
- Input Variables:
  - THREADS Number of threads used for multithreaded tools, must match #BSUB -n
    - example value: 16
  - MAIN_DIR Root directory for all input/output subolders in the workflow
    - example value: "/rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs"
  - INPUT_FASTQ reads used to polish assembly, usually unzipped, filtered and trimmed reads from step 2 that created the assembly in step 3
    - example value: "${MAIN_DIR}/2_TRIM_data/SampleA_good/SampleA.pass.porechop.chopped.fastq"
  - ASSEMBLY assembly, either previously polished or unpolished
    - example value: "${MAIN_DIR}/3_assembly/SampleB_good/hifi_v2/HiFiasm_B_v2_assembly.p_ctg.fa"
  - OUT_DIR Output directory where result go, will create a folder
    - example value: "${MAIN_DIR}/4_polishing/SampleA_good"
  - MAPPING_FILE shared directory for mapping.paf
    - example value: "${OUT_DIR}/mapping.paf"
  - POLISHED_ASSEMBLY name of output polished assembly
    - example value: "${OUT_DIR}/${NAME}.p_ctg.polished.fasta"

## 5_scaffolding.sh
 - what it does: Creates scaffolds from contigs using RagTag and then uses Tidk to detect telomeres
 - Input Variables:
     - DRAFT_ASSEMBLY Path to the raw draft genome assembly (before scaffolding).
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/3_assembly/SampleB_raw/SampleB_raw.p_ctg.fa
     - REFERENCE_ASSEMBLY Reference genome used to guide RagTag scaffolding.
          - example value: /rs1/researchers/c/ccgoller/epi2me/waxworm_reference_genome/GCF_026898425_CSIRO_AGI_GalMel_v1_genomic.fasta
     - RAGTAG_OUT Directory where RagTag results will be saved.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/6_scaffolding/SampleB
     - SCAFFOLDED_ASSEMBLY Final scaffolded genome output by RagTag.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/6_scaffolding/SampleB/ragtag.scaffold.fasta
     - TIDK_OUT: Prefix used for Tidk output file names.
          - example value: telomeres
     -  --string "STRING" The telomeric repeat sequence Tidk will search for (common in Lepidoptera).
          - example value:"AACCT"
      
  ## 6_mummer.sh
  - what it does: Uses MUMmer to align a scaffolded genome against a reference genome
  - Input Variables:
     - NAME prefix used for naming output files.
         - example value: scaffoldsA_vs_REF
     - THREADS Number of CPU threads to use for the job, must match $BSUB -n 
         - example value: 16
     - REF Path to the reference genome (used as the alignment target).
         - example value: /rs1/researchers/c/ccgoller/epi2me/waxworm_reference_genome/GCF_026898425_CSIRO_AGI_GalMel_v1_genomic.fasta
     - QUERY Path to the query genome (the genome to align against the reference).
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/6_scaffolding/SampleA_v2/ragtag.scaffold.fasta
     - OUTDIR Directory where all alignment and plotting output will be saved.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/7_alignment/mummer/scaffoldsA_vs_REF
     - PREFIX  Full prefix path for output files (combines OUTDIR and NAME).
         - example value: "${OUTDIR}/${NAME}" which evalueates to /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/7_alignment/mummer/scaffoldsA_vs_REF/scaffoldsA_vs_REF

  
## 7_QC_post.sh
- what it does: Asseses quality of hifi assembly using assembly stats, BUSCO and QUAST
- Input Variables:
     - THREADS Number of threads used for multithreaded tools like quast, must match #BSUB -n
          - example value: 16
     - MAIN_DIR Root directory for all input/output subfolders in this workflow.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs
     - ASSEMBLY Path to the final polished genome assembly file used for QC analysis.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/4_polishing/SampleA_2/HiFiasm_A_v2_assembly.bp.p_ctg.polished.fasta
     - QC_POST Parent output directory for all QC tools' results. 
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/5_QC_post/SampleA/polished
     - QUAST_OUT Output directory for QUAST results.
          - example value: $QC_POST/quast
     - STATS_OUT Output directory for assembly-stats results.
          - example value: $QC_POST/assembly_stats
            
## 8_annotation.sh
- what it does: currently has memory issues and does not run fully, but should run repeat modeler to identify repeats and non-genic sequences and exons, use the repeatmasker to soft mask the non-genic sequences. Then use funannotate to identify putative gene models within the non-masked regions
- Input Variables:
  - ANNO_NAME Name identifier for the annotation run, used to generate output paths and organize results.
          - example value: SAMPLE_A
      - GENOME Path to the genome assembly file to be annotated.
          - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/3_assembly/SampleA_v2/HiFiasm_A_v2_assembly.p_ctg.fa
      - THREADS Number of threads used for multithreaded tools like RepeatModeler, RepeatMasker, and Funannotate; must match #BSUB -n in job scheduler.
           - example value: 32
      - protein_DB Path to the protein evidence FASTA file used for gene prediction in Funannotate.
           - example value: /rs1/researchers/c/ccgoller/wwconsulting/diamond/DBs/GCF_026898425.1/protein.faa
      - OUTDIR Output directory where all result files and subdirectories (e.g., repeatmodeler, repeatmasker, funannotate) will be stored.
           - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/8_annotation/SAMPLE_A
      - SCRATCH_DIR Temporary scratch directory used for intermediate file storage during processing steps (e.g., RepeatModeler).
         - example value: /share/wgsshogun/kamckeev
      - MASKED_GENOME Path to the genome file after being processed by RepeatMasker. This is dynamically generated and used as input for Funannotate.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/8_annotation/SAMPLE_A/repeatmasker/HiFiasm_A_v2_assembly.p_ctg.fa.masked
       - MASK_SHORT The masked genome file with renamed headers, generated from MASKED_GENOME for use in Funannotate.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/SCRIPTS/outputs/8_annotation/SAMPLE_A/output.fna
       - FUNANNOTATE_DB Environment variable used to specify the path to the Funannotate database directory.
         - example value: /rs1/researchers/c/ccgoller/wwconsulting/funannotate/DBs
