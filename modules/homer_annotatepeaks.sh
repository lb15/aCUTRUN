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

#$ -l h_rt=6:00:00

#$ -pe smp 4


INPUTBED=$1
DIRECTORY="${INPUTBED%/*}"
INPUTBEDFILE="${INPUTBED##*/}"
GENOME=$2
OUT=$3
PROJECT_ROOT=$4
LOG_DIR=$5

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/annohomer_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

GENOME_LOC="${PROJECT_ROOT}/tools/homer/data/genomes/mm10"
GTF="${PROJECT_ROOT}/resources/mm10.refGene.gtf"

echo >&2 "Genome: ${GENOME_LOC}"

annotatePeaks.pl $INPUTBED $GENOME_LOC \
	-gtf $GTF \
	-annStats "$DIRECTORY"/"${INPUTBEDFILE%.*}"_annostats.txt > "$DIRECTORY"/"${INPUTBEDFILE%.*}"_"$OUT".txt
