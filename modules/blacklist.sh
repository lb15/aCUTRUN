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
#$ -m ea                           #--email when done


########### LOAD ENVIRONMENT/MODULES ###########

module load CBI bedtools2/2.30.0

########### DEFINE ARGUEMNTS ##############
peaks1=$1
PROJECT_ROOT=$2
LOG_DIR=$3

blacklist=$PROJECT_ROOT/resources/mm10_blacklist_ENCFF547MET.bed

peaks1_dir=${peaks1%/*}
peaks1_base=${peaks1##*/}

bedtools intersect \
	-a $peaks1 \
	-b $blacklist \
	-v > $peaks1_dir/"${peaks1_base%.*}"_blklist.bed


