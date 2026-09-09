## This script takes the reference genome prepared by modify_gatk_hg38.sh, and
## modifies it to create a reference suitable for RNA-Seq analysis. 
## The modifications include removing the Lambda and pUC19 sequences, masking 
## the relevant regions and adding the ERCC sequences.

METH_HOME='/path/to/references/hg38/GRCh38/bundle/hg38/emseq'
RNA_HOME='/path/to/rnaseq/references/'

CD ${RNA_HOME} 

## Remove the pUC and Lambda sequences from the reference genome by just 
## dropping the last 2 sequences from the fasta file. The last 2 sequences are 
## pUC19 and Lambda, respectively.
sed -n '1,30997794p' "${METH_HOME}/hg38-lambda-pUC.fa" > "GRCh38.gatk_bundle.gencode_subset.ERCC92.fa"

## Concatenate the ERCC spike-ins at the end
zcat ERCC92.fa.gz >> "GRCh38.gatk_bundle.gencode_subset.ERCC92.fa"

## Create the chrY-masked version. The BED file was created manually and is a
## single-line file that contains the coordinates chrY\t1\t57227415
## Notably, the reference genome is already PAR-Y masked.
micromamba activate bedtools
bedtools maskfasta \
  -fi GRCh38.gatk_bundle.gencode_subset.ERCC92.fa \
  -bed GRCh38.chrY.bed \
  -fo GRCh38.gatk_bundle.gencode_subset.y_masked.ERCC92.fa
micromamba deactivate

## Get the GENCODE v46 primary assembly GTF and decompress it
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_46/gencode.v46.primary_assembly.annotation.gtf.gz
gunzip -c gencode.v46.primary_assembly.annotation.gtf.gz > gencode.v46.primary_assembly.annotation.gtf
## Add the ERCC spike-ins to the GTF file.
zcat ERCC92.gtf.gz >> gencode.v46.primary_assembly.annotation.gtf

## Collect the GATK sequence IDs for use when modifying the GTF
egrep '^>' GRCh38.gatk_bundle.gencode_subset.y_masked.ERCC92.fa > gatk_seqids.txt