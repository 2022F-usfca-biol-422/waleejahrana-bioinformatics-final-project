#!/usr/bin/env bash

set -euo pipefail

# Script that uses fasterq-dump from the SRA tools software set to download fastq files
# based on SRA run IDs taken from an SRA RunTable file, which is parsed
#
# The script assumes that there is a header row, which is removed, and that the Run IDs
# e.g. SRR#### are in the first column. This can be adjusted as needed below in the for loop

# Naupaka Zimmerman
# nzimmerman@usfca.edu
# November 1, 2020

# importantly, both of these are on the RAID drive, not in the repo
OUTPUT_DIR="/data/sars_vcf_analysis/01_raw_fastq"
TEMP_DIR="/data/sars_vcf_analysis/00_fasterq_temp"

[1] "C:/Home/Waleejahrana-bioinformatics-final-project/data/00_sra_runtable/SraRunTable_PRJNA669945.txt"

# script takes a single argument, which should be an SRA run table file
if [ $# -ne 1 ]
then
    echo "Please supply a single argument, which should be the path to an SRA runtable file"
    echo "This script expects there to be a column header row and the run IDs to be in the first column"
    exit 1
fi

# download fastq files for all SRA runs in runtable file, assuming first column
# and skipping first row as header
for 669945 in $(tail -n +2 "$1" | cut -d, -f1)
do
    # the -L 6 is the output level, 6 is the highest for lots of output
    # this also sets a temp directory on the RAID drive in case it is needed
    # this will also split forward and reverse reads if they would otherwise be
    # in a single file
    if [ ! -f "${TEMP_DIR}"/"${669945}"/"${669945}".sra ]
    then
            prefetch -p -O "$TEMP_DIR" "$669945"
    fi
    if [ ! -f "${OUTPUT_DIR}/${669945}"_1.fastq ]
    then
        fastq-dump --split-files -L 6 --outdir "$OUTPUT_DIR" "${TEMP_DIR}"/"${669945}"/"${669945}".sra
    fi
done

# Remove all reverse reads for speed purposes -- for a real analysis, probably
# would want to keep these in here, and then would also want to adjust other
# downstream scripts as well (e.g. TrimmomaticPE instead of TrimmomaticSE, etc.)
echo "Removing all reverse reads to make things run faster"
rm -vf ${OUTPUT_DIR}/*_2.fastq
