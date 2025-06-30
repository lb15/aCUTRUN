#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=50G
#$ -l scratch=10G
#$ -l h_rt=96:00:00

############## LOAD ENVIRONMENT #############
module load CBI miniforge3
conda activate CUTRUN

############## DEFINE ARGUMENTS ############
proj=$1
sample=$2
projdir=$3
PROJECT_ROOT=$4
LOG_DIR=$5
control=$6

############## DEFINE DIRECTORIES #############

workdir=$projdir/$sample/
logdir=$workdir/logs
dupmarkdir=$workdir/dupmark
dedupdir=$workdir/dedup

dupmacsdir=$dupmarkdir/MACS2_dupmark
dedupmacsdir=$dedupdir/MACS2_dedup

mkdir $dupmacsdir
mkdir $dedupmacsdir

crtools="${PROJECT_ROOT}/tools/cutruntools/"

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/macs2_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

echo >&2 "Peak calling using MACS2... "

macs2 callpeak -t "${dupmarkdir}/${sample}_henikoff_dupmark_120bp.bam" \
	-g mm \
	-f BAMPE \
	-n "$sample"_dupmark \
	--outdir $dupmacsdir \
	-q 0.01 \
	-B \
	--SPMR \
	--keep-dup all 2> "${logdir}/${sample}_dupmark_120bp.macs2.txt"

macs2 callpeak -t "${dupmarkdir}/${sample}_henikoff_dupmark_120bp.bam" \
	-g mm \
	-f BAMPE \
	-n "$sample"_dedup \
	--outdir $dedupmacsdir \
	-q 0.01 \
	-B \
	--SPMR 2> "${logdir}/${sample}_dedup_120bp.macs2.txt"

>&2 echo "Finished"

if [ "$control" == "" ]
then
>&2 echo "No control run"
else
	macsdupdir="${projdir}/${sample}_vs_${control}/MACS2_dupmark"
	macsdedupdir="${projdir}/${sample}_vs_${control}/MACS2_dedup"
	mkdir -p $macsdupdir
	mkdir -p $macsdedupdir

	controldir=$projdir/$control
	vslogdir="${projdir}/${sample}_vs_${control}/logs"

	mkdir $vslogdir

	## keep dups
	macs2 callpeak -t "${dupmarkdir}/${sample}_henikoff_dupmark_120bp.bam" \
		-c "${controldir}/dupmark/${control}_henikoff_dupmark_120bp.bam" \
		-g mm \
		-f BAMPE \
		-n "$sample"_vs_"$control"_dupmark \
		--outdir $macsdupdir \
		-q 0.01 \
		-B --SPMR \
		--keep-dup all 2> "${vslogdir}/${sample}_vs_${control}_dupmark_120bp.macs2.txt"

	## no dups
	macs2 callpeak -t "${dupmarkdir}/${sample}_henikoff_dupmark_120bp.bam" \
		-c "${controldir}/dupmark/${control}_henikoff_dupmark_120bp.bam" \
		-g mm \
		-f BAMPE \
		-n "$sample"_vs_"$control"_dedup \
		--outdir $macsdedupdir \
		-q 0.01 \
		-B --SPMR 2> "${vslogdir}/${sample}_vs_${control}_dedup_120bp.macs2.txt"

fi


