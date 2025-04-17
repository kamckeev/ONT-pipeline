# ONT-pipeline
Pipeline for assembling or rebasecalling raw Oxford nanopore reads

The pipeline is comprised of 8 scripts following 8 steps of genome assembly. Scripts are depositid here on git hub as well as on Dr. Goller's space on NCSU Hazel cluster. In general, all user defined variables which may change between different datasets are defined in all caps (ex: OUTPUT_FASTQ_DIR) and later references in the script (ex: "$OUTPUT_FASTQ_DIR"). Users should only change the directory paths to identify their specific dataset at the beginning of the script to avoid creating errors. Some software includes variables specific to the software (ex: read depth of data), which the user may wish to alter for their specific dataset. 

## 1_QC_preassembly.sh
 - input
## 2_trim_reads.sh

## 3_hifiasm_assembly.sh

## 5_QC_post.sh

## 6_mummer.sh

## 7_scaffolding.sh

## 8_annotation.sh
