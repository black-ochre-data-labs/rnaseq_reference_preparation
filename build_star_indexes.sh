#!/bin/bash
#SBATCH -p tki_bodl
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --time=24:00:00
#SBATCH --mem=128GB
#SBATCH -o ~/logs/%x_%j.out
#SBATCH -e ~/logs/%x_%j.err
#SBATCH --constraint=knl

module add micromamba
eval "$(micromamba shell hook --shell=bash)"
micromamba activate star-2.7.11

REF_HOME=/path/to/rnaseq/references
GTF=${REF_HOME}/gencode.v46.primary_assembly.annotation.gatk_seqids.gtf
VCF=${REF_HOME}/variants/PROPHECY_unrel_edited_0.5.vcf
CORES=16

## Setup the GTF. Not sure if it'll be gzipped or not
if [ ! -f "${GTF}" ]; then
  echo -e "Couldn't find ${GTF}"
  GTFZ=${GTF}.gz
  if [ ! -f "${GTFZ}" ]; then
    echo -e "Couldn't find ${GTFZ}"
    exit 1
  else
    echo -e "Extracting ${GTFZ}"
    gunzip -c ${GTFZ} > ${GTF}
  fi
fi

## Repeat for the VCF
if [ ! -f "${VCF}" ]; then
  echo -e "Couldn't find ${VCF}"
  VCFZ=${VCF}.gz
  if [ ! -f "${VCFZ}" ]; then
    echo -e "Couldn't find ${VCFZ}"
    exit 1
  else
    echo -e "Extracting ${VCFZ}"
    gunzip -c ${VCFZ} > ${VCF}
  fi
fi

#################################
## The PAR-Y masked star index ##
#################################
FA=${REF_HOME}/GRCh38.gatk_bundle.gencode_subset.ERCC92.fa
if [ ! -f "${FA}" ]; then
  echo -e "Couldn't find ${FA}"
  FAZ=${FA}.gz
    if [ ! -f "${FAZ}" ]; then
    echo -e "Couldn't find ${FAZ}"
    exit 1
  else
    echo -e "Extracting ${FAZ}"
    gunzip -c ${FAZ} > ${FA}
  fi
fi
STAR \
  --runThreadN ${CORES} \
  --runMode genomeGenerate \
  --genomeDir ${REF_HOME}/star/GRCh38_gatk_bundle_gencode_subset_ERCC92 \
  --genomeFastaFiles ${FA} \
  --sjdbGTFfile ${GTF}

STAR \
  --runThreadN ${CORES} \
  --runMode genomeGenerate \
  --genomeDir ${REF_HOME}/star/GRCh38_PROPHECY_gatk_bundle_gencode_subset_ERCC92 \
  --genomeFastaFiles ${FA} \
  --sjdbGTFfile ${GTF} \
  --genomeTransformVCF ${VCF} \
  --genomeTransformType Haploid 

echo -e "Indexing the PAR-Y masked genome complete"

#############################
## The y-masked star index ##
#############################
FA=${REF_HOME}/GRCh38.gatk_bundle.gencode_subset.y_masked.ERCC92.fa
if [ ! -f "${FA}" ]; then
  echo -e "Couldn't find ${FA}"
  FAZ=${FA}.gz
    if [ ! -f "${FAZ}" ]; then
    echo -e "Couldn't find ${FAZ}"
    exit 1
  else
    echo -e "Extracting ${FAZ}"
    gunzip -c ${FAZ} > ${FA}
  fi
fi
STAR \
  --runThreadN ${CORES} \
  --runMode genomeGenerate \
  --genomeDir ${REF_HOME}/star/GRCh38_gatk_bundle_gencode_subset_y_masked_ERCC92 \
  --genomeFastaFiles ${FA} \
  --sjdbGTFfile ${GTF}

STAR \
  --runThreadN ${CORES} \
  --runMode genomeGenerate \
  --genomeDir ${REF_HOME}/star/GRCh38_PROPHECY_gatk_bundle_gencode_subset_y_masked_ERCC92 \
  --genomeFastaFiles ${FA} \
  --sjdbGTFfile ${GTF} \
  --genomeTransformVCF ${VCF} \
  --genomeTransformType Haploid 

echo -e "Indexing the chrY masked genome complete"  

micromamba deactivate

