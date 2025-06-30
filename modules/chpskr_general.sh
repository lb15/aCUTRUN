#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=50G
#$ -l scratch=10G
#$ -l h_rt=4:00:00

######### LOAD ENVIRONEMNT/MODULES ########
module load CBI r/4.4

######## DEFINE ARGUMENTS ########
peakfile=$1
PROJECT_ROOT=$2
LOG_DIR=$3
outdir=${peakfile%/*}
base=${peakfile##*/}
filename=${base%.*}

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/chpkskr_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

script_dir=$PROJECT_ROOT/modules/

######## RUN R SCRIPT #######
Rscript $script_dir/chipseeker_general.R $outdir $peakfile $filename

