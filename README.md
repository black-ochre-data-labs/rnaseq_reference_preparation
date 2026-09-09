# PROPHECY RNA-Seq Reference Preparation

This repository contains all scripts and used code used to prepare the reference
sequences and annotations for the primary RNA-Seq analysis.
Whilst most scripts were executed, some represent extracts from larger 
multi-omic pipelines, with key steps extracted and pasted into stand-alone 
scripts.

The primary genomic sequences were initially obtained from the [GATK hg38 bundle](https://gatk.broadinstitute.org/hc/en-us/articles/360035890811-Resource-bundle),
with all annotations for the primary asssembly obtained from [GENCODE Release 46](https://www.gencodegenes.org/human/release_46.html).

The key processes are:

1. Editing the reference genome to remove sequences which were not required
2. Masking:
   1. The entire chrY sequence for female participants
   2. The chrY pseudo-autosomal region (PAR) for male participants
3. Modifying the annotations so all sequence identifiers match the modified genomic reference
4. Creating consensus variants for incorporation into the *STARconsensus* method when aligning reads to the genome
5. Creating STAR indexes for each sex-specific genome, including
   1. The standard GRCh38 reference as created in the first step
   2. A version of the GRCh38 reference for which the index was variant-aware, in keeping with the *STARconsensus* method