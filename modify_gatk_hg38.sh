## Script prepared by Alastair Ludington and executed as part of the reference 
## preparation for the PROPHECY EMS-EQ pipeline. 
##
## This script downloads the GRCh38 reference genome, removes 
## alternate/decoy/EBV/HLA sequences, appends pUC19 and Lambda sequences, 
## and builds a bwa-meth index.
## The script was also executed inside a singularity container with all tools
## installed.
## The container was built from the dockerfile included within this repository
##
## The reference sequence for the RNA-Seq aalysis was subsequently obtained by 
## modifying this reference to remove the Lambda and pUC19 sequences, mask the 
## relevant regions and adding the ERCC sequences.

# Fixed location for EMSEQ reference genome. Pseudo path
REFDIR='/path/to/references/hg38/GRCh38/bundle/hg38/emseq'

# Bucket URL
# https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/
BUCKET='gs://genomics-public-data/references/hg38/v0'

# pUC19 url
PUC_URL='https://www.neb.com/en-au/-/media/nebus/page-images/tools-and-resources/interactive-tools/dna-sequences-and-maps/text-documents/puc19fsa.txt?rev=6e10f4c4a4234d638e401cd2f4578ef0&hash=389A2A99C9215C546402EAE28B0410AC'

# Lambda_NEB url - built from NC_001416.1 reference genome by applying mutations: 37589 C->T, 45352 G->A, 37742 C->T and 43082 G->A
LAMBDA_URL='https://www.neb.com/en-au/-/media/nebus/page-images/tools-and-resources/interactive-tools/dna-sequences-and-maps/text-documents/lambdafsa.txt\?rev\=c0c6669b9bd340ddb674ebfd9d55c691\&hash\=D57C28280DEC9F8A9FC23DE4465EDA78'

echo -e "\nREFERENCE DIRECTORY: ${REFDIR}"
echo "REFERENCE BUCKET: ${BUCKET}" 
echo "PUC19 URL: ${PUC_URL}" 
echo -e "LAMBDA URL: ${LAMBDA_URL}\n"

# ---------------------------------------------------------------------------- #
# Exit if not on DUG - assuming head node never changes...
if [[ $(hostname) != 'pvnc0025' ]]; then
    { echo "Not running on DUG. Exiting.";exit 1; }
fi

# ---------------------------------------------------------------------------- #
# Change into reference directory on HOST (DUG)
if [ ! -d "${REFDIR}" ]; then
    mkdir -pv "${REFDIR}"
fi
cd "${REFDIR}" || exit 1

# ---------------------------------------------------------------------------- # 
# Download reference genome
echo "[gsutil] Download 'Homo_sapiens_assembly38.fasta'"
gsutil ls "${BUCKET}" |
    grep 'Homo_sapiens_assembly38.fasta$' |
    gsutil -m cp -I .

# ---------------------------------------------------------------------------- #
# Download pUC19 and Lambda

echo "[curl] Download pUC19 sequence from NEB"
curl -L -o 'pUC19.fasta' "${PUC_URL}"
md5sum 'pUC19.fasta' > 'pUC19.fasta.md5'

echo "[curl] Download Lambda sequence from NEB"
curl -L -o 'lambda_NEB.fasta' "${LAMBDA_URL}"
md5sum 'lambda_NEB.fasta' > 'lambda_NEB.fasta.md5'

# ---------------------------------------------------------------------------- #
# Prepare final reference genome file
echo "[seqkit] Remove alternate/decoy/EBV/HLA sequences from 'Homo_sapiens_assembly38.fasta'"
seqkit grep -v -r -p '_alt|_decoy|EBV|^HLA' 'Homo_sapiens_assembly38.fasta' > 'hg38-lambda-pUC.fasta'

echo "[seqkit] Append pUC19 & Lambda sequences to reference genome"
seqkit seq 'pUC19.fasta' >> 'hg38-lambda-pUC.fasta'
seqkit seq 'lambda_NEB.fasta' >> 'hg38-lambda-pUC.fasta'

echo '[seqkit] Index reference genome'
seqkit faidx 'hg38-lambda-pUC.fasta'

echo "[md5sum] Create MD5 of final reference file 'hg38-lambda-pUC.fasta'"
md5sum 'hg38-lambda-pUC.fasta' > 'hg38-lambda-pUC.fasta.md5'

# ---------------------------------------------------------------------------- #
# Build bwa-meth index + move to dedicated directory
echo '[bwameth] Build BWA2 index'
mkdir -pv bwameth
bwameth.py index-mem2 hg38-lambda-pUC.fasta
mv -v hg38-lambda-pUC.fa.bwameth.c2t  hg38-lambda-pUC.fa.bwameth.c2t.0123  hg38-lambda-pUC.fa.bwameth.c2t.amb  \
    hg38-lambda-pUC.fa.bwameth.c2t.ann  hg38-lambda-pUC.fa.bwameth.c2t.bwt.2bit.64  hg38-lambda-pUC.fa.bwameth.c2t.fai  \
    hg38-lambda-pUC.fa.bwameth.c2t.pac bwameth