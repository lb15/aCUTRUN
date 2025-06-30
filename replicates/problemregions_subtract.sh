#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l h_rt=72:00:00

####### DEFINE ENVIRONMENT/MODULES #####
module load CBI bedtools2/2.30.0

###### DEFINE ARGUMENTS #######
peaks=$1
PROJECT_ROOT=$2
LOG_DIR=$3

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/problematic_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

probregs="${PROJECT_ROOT}/resources/problem_regions_mm10.bed"

output="${peaks%.bed*}_noprob.bed" 

echo >&2 "INPUT peaks: ${peaks}"
echo >&2 "Problematic regions: ${probregs}"
echo >&2 "OUTPUT peaks: ${output}"

bedtools subtract -a $peaks -b $probregs -A > "$output"
