#' This script takes the IDs from the sequence headers in the GATK reference
#' genome and replaces the seqinfo in the GENCODE GTF with these IDs. 

library(Biostrings)
library(rtracklayer)
library(tidyverse)

## Load the GTF & pull out the existing seqinfo
gtf <- import.gff("gencode.v46.primary_assembly.annotation.gtf.gz")
sq <- seqinfo(gtf)

## This file was obtained using egrep '^>' Homo_sapiens_assembly38.fasta > gatk_seqids.txt
gatk_ids <- read_lines("gatk_seqids.txt")
gc_to_gatk <- tibble(hdr = str_remove(gatk_ids, "^>")) %>% 
  mutate(
    gatk = str_extract(hdr, "^[^ ]+"),
    AC = str_replace(hdr, ".+AC:([^ ]+)  .+", "\\1")
  ) %>% 
  dplyr::select(gatk, AC) %>% 
  dplyr::filter(grepl("chr", gatk)) %>% 
  mutate(
    gencode = case_when(
      gatk %in% paste0("chr", c(1:22, "X", "Y", "M")) ~ gatk,
      TRUE ~ AC
    ),
    gatk = setNames(gatk, gencode)
  ) %>% 
  pull(gatk)
## Check we've captured everything
setdiff(seqlevels(sq), names(gc_to_gatk))

gatk_sq <- Seqinfo(seqnames = unname(gc_to_gatk[seqlevels(sq)]))
seqinfo(gtf, new2old = seq_along(seqlevels(gatk_sq))) <- gatk_sq

gtf %>% 
  export.gff("gencode.v46.primary_assembly.annotation.gatk_seqids.gtf")

