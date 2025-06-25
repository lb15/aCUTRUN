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
#$ -m ea                           #--email when done

############# LOAD ENVIRONMENT ####################


############## DEFINE ARGUMENTS ####################

project=$1
sample=$2
projdir=$3
PROJECT_ROOT=$4
LOG_DIR=$5

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/bamtobigwig_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

############# bamCoverage #################

bam="${projdir}/${sample}/dupmark/${sample}_henikoff_dupmark_120bp.bam"
out="${projdir}/${sample}/dupmark/${sample}_henikoff_dupmark_120bp_RPGC.bw"

bamCoverage -b $bam -o $out \
	--normalizeUsing RPGC \
	--effectiveGenomeSize 2652783500 \
	--extendReads \
	--binSize 10

echo >&2 "finished dupmarked.120"

bam2="${projdir}/${sample}/dedup/${sample}_henikoff_dedup_120bp.bam"
out2="${projdir}/${sample}/dedup/${sample}_henikoff_dedup_120bp_RPGC.bw"

bamCoverage -b $bam2 -o $out2 \
        --normalizeUsing RPGC \
        --effectiveGenomeSize 2652783500 \
        --extendReads \
        --binSize 10

echo >&2 "finished dedup.120"



