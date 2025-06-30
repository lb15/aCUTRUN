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

################ LOAD ENVIRONMENT/MODULES #########
module load CBI bowtie2/2.4.2 samtools/1.10

project=$1
sample=$2
projdir=$3
PROJECT_ROOT=$4
LOG_DIR=$5

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/ecoli_${project}_${sample}_${JOB_ID}.log"

workdir="${projdir}/${sample}/"
crtools="${PROJECT_ROOT}/tools/cutruntools/"
trimdir=$workdir/trimmomatic
logdir=$workdir/logs
spikedir=$workdir/spikein
bt2idx="${PROJECT_ROOT}/resources/Escherichia_coli_K_12_MG1655/NCBI/2001-10-15/Sequence/Bowtie2Index/genome"

mkdir $spikedir

bowtie2 -p "${NSLOTS:-1}" \
	--end-to-end \
	--very-sensitive \
	--no-overlap \
	--no-dovetail \
	--no-mixed \
	--no-discordant \
	--phred33 \
	-I 10 -X 700 \
	-x $bt2idx \
	-1 "${trimdir}/${sample}_1_kseq_paired.fastq.gz" \
	-2 "${trimdir}/${sample}_2_kseq_paired.fastq.gz" \
	-S "${spikedir}/${sample}_bowtie2_spikeIn.sam" 2> "${logdir}/${sample}_bowtie2_spikeIn.txt"

samtools view -bS "${spikedir}/${sample}_bowtie2_spikeIn.sam" > "${spikedir}/${sample}_bowtie2_spikeIn.bam"

