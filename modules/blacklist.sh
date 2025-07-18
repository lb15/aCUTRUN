#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l scratch=10G
#$ -l h_rt=24:00:00


########### LOAD ENVIRONMENT/MODULES ###########

module load CBI bedtools2/2.30.0

########### DEFINE ARGUMENTS ##############
peaks1=$1
PROJECT_ROOT=$2
LOG_DIR=$3

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/blacklist_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

####### BLACKLISTED SITES FROM ENCODE ######
blacklist=$PROJECT_ROOT/resources/mm10_blacklist_ENCFF547MET.bed

peaks1_dir=${peaks1%/*}
peaks1_base=${peaks1##*/}

####### RUN BEDTOOLS INTERSECT ######
bedtools intersect \
	-a $peaks1 \
	-b $blacklist \
	-v > $peaks1_dir/"${peaks1_base%.*}"_blklist.bed


