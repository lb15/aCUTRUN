#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l scratch=10G
#$ -l h_rt=10:00:00

######## SCRIPT DESCRIPTION #######

## This script takes in a diffbind_samplesheet.csv that describes the samples, column descriptions here: https://bioconductor.org/packages/devel/bioc/vignettes/DiffBind/inst/doc/DiffBind.pdf.
## Script assumes the diffbind_samplesheet.csv file is in a main project folder and subfolder called "diffbind". For example CR61_63_64/diffbind/CR61_63_64_diffbind_samplesheet.csv.

## The beginning name of the samplesheet will be used to identify the folder and consensus peak files created in from the submit_replicates.sh pipeline.
## Output will be placed in same directory as the location of diffbind_samplesheet.csv

######## LOAD ENVIRONMENT/MODULES ######
module load CBI r/4.4

###### DEFINE ARGUMENTS ########
file=$1
workdir="${file%/*}"
projdir="${file%/diffbind*}"
base=${file##*/}
projname="${base%_diffbind_samplesheet.csv}"
peak_list="${projdir}/${projname}_dupmark_consensus_peaks_merged.bed"


PROJECT_ROOT="$SGE_O_WORKDIR"
script_dir="${PROJECT_ROOT}/accessory/"

## LOG directory
LOG_DIR="${workdir}/log_${JOB_ID}_diffbind"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/sub_diffbind_${JOB_ID}.log"

# Redirect both stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

#### RUN DIFFBIND R SCRIPT
Rscript $script_dir/diffbind_consensus.R $file $dir $name $peak_list

