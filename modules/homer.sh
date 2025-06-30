#!/bin/env bash
#!/bin/bash                         #-- what is the language of this shell

#                                  #-- Any line that starts with #$ is an instruction to SGE

#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l scratch=20G
#$ -l h_rt=96:00:00
#$ -pe smp 4


########### LOAD ENVIRONMENT ##########

########## DEFINE ARGUMENTS ##########
INPUTBED=$1
DIRECTORY="${INPUTBED%/*}"
INPUTBEDFILE="${INPUTBED##*/}"
GENOME_LOC=$2
SIZE=$3
PROJECT_ROOT=$4
LOG_DIR=$5

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/homer_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

######## PARAMETERS #####
SCRIPT_DIR="${PROJECT_ROOT}/tools/homer/bin"
echo >&2 $GENOME_LOC
echo >&2 $DIRECTORY

"${SCRIPT_DIR}/findMotifsGenome.pl" $INPUTBED $GENOME_LOC "$DIRECTORY"/"${INPUTBEDFILE%.*}"_"$SIZE"bp -size $SIZE -p "${NSLOTS:-1}"
