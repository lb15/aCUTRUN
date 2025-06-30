#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -o /dev/null
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l scratch=10G
#$ -l h_rt=72:00:00

####### LOAD ENVIRONMENT/MODULES ######
module load CBI miniforge3
conda activate CUTRUN

###### DEFINE ARGUMENTS #######
input_file=$1
output_file=$2
LOG_DIR=$3

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/bigwigAvg_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

####### BigWig Average ######
bigwigAverage -b $(sed 's/\x0//g' "$input_file") -o $output_file

