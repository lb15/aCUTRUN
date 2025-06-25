#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=50G
#$ -l scratch=10G
#$ -l h_rt=02:00:00

######### LOAD ENVIRONMENT/MODULES #####
module load CBI r/4.3

####### DEFINE ARGUMENTS ########
file=$1
workdir=$2
PROJECT_DIR=$3
LOG_DIR=$4

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/metrics_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

script_dir="${PROJECT_DIR}/modules/"

######### RUN SCRIPT ########
echo >&2 "Starting script"

Rscript $script_dir/cutrun_metrics.R $file $workdir


