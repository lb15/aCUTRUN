#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l scratch=10G
#$ -l h_rt=72:00:00

######## LOAD ENVIRONMENT/MODULES #####
module load CBI r/4.4

####### DEFINE ARGUMENTS ####
sample=$1
project=$2
projdir=$3
PROJECT_ROOT=$4
LOG_DIR=$5

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/getSpike_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

script_dir="${PROJECT_ROOT}/modules/get_spikein.R"

Rscript $script_dir $project $sample $projdir

