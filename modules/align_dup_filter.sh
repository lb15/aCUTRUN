#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=20G
#$ -l scratch=500G
#$ -l h_rt=96:00:00
#$ -m ea                           #--email when done
#$ -pe smp 4

######### LOAD ENVIRONMENT AND MODULES #########
source /wynton/home/reiter/lb13/miniconda3/bin/activate CutRun

module load CBI bowtie2/2.4.2 samtools/1.10 picard/2.24.0

######### DEFINE ARGUMENTS ########

project=$1
sample=$2
projdir=$3
PROJECT_ROOT=$4
LOG_DIR=$5

######### SET UP $TMPDIR FOR SPEED #######

if [[ -z "$TMPDIR" ]]; then
  if [[ -d /scratch ]]; then TMPDIR=/scratch/$USER; else TMPDIR=/tmp/$USER; fi
  mkdir -p "$TMPDIR"
  export TMPDIR
fi

cd "$TMPDIR"

######### SET UP DIRECTORIES ########
## TMPDIR 
workdir="${TMPDIR}/${project}/${sample}/"
aligndir=$workdir/alignment
dupmarkdir=$workdir/dupmark
dedupdir=$workdir/dedup

mkdir $aligndir
mkdir $dupmarkdir
mkdir $dedupdir

## Project directory
trimdir=$projdir/$sample/trimmomatic
logdir=$projdir/$sample/logs
dupmarkdest=$projdir/$sample/dupmark
dedupdest=$projdir/$sample/dedup

mkdir $dupmarkdest
mkdir $dedupdest

## Tools directory
crtools=$PROJECT_ROOT/tools/cutruntools/
bt2idx=$PROJECT_ROOT/resources/mm10/

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/align_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

echo >&2 "Starting bowtie alignment using Henikoff Lab parameters"

## alignment paramters from CUT&RUNtools
#bowtie2 -p "${NSLOTS:-1}" --dovetail --phred33 -x $bt2idx/mm10 -1 $trimdir/"$sample"_1_kseq_paired.fastq.gz -2 $trimdir/"$sample"_2_kseq_paired.fastq.gz -S $aligndir/"$sample"_aligned_crtools.sam 2> $logdir/"$sample"_bowtie2_stats_crtools.txt  
#samtools view -bS $aligndir/"$sample"_aligned_crtools.sam  > $aligndir/"$sample"_aligned_crtools.bam
#rm $aligndir/"$sample"_aligned_crtools.sam

## alignment parameters from Henikoff lab
bowtie2 -p "${NSLOTS:-1}" --local --very-sensitive-local --no-unal --no-mixed --no-discordant --phred33 -I 10 -X 700 -x $bt2idx/mm10 -1 $trimdir/"$sample"_1_kseq_paired.fastq.gz -2 $trimdir/"$sample"_2_kseq_paired.fastq.gz -S $aligndir/"$sample"_aligned_henikoff.sam 2> $logdir/"$sample"_bowtie2_stats_henikoff.txt

echo >&2 "Filtering multimappers by minimum Quality score of 2"
minQualityScore=2
samtools view -q $minQualityScore -bS $aligndir/"$sample"_aligned_henikoff.sam > $aligndir/"$sample"_aligned_henikoff.bam

>&2 echo "Filtering and alignment complete"
>&2 echo "Starting sorting and marking duplicates"

java -Xmx8g -Djava.io.tmpdir=$aligndir/ -jar $PICARD_HOME/picard.jar SortSam \
	INPUT=$aligndir/"$sample"_aligned_henikoff.bam \
	OUTPUT=$aligndir/"$sample"_aligned_henikoff_sort.bam \
	SORT_ORDER=coordinate \
	TMP_DIR=$TMPDIR

picard MarkDuplicates \
INPUT="${aligndir}/${sample}_aligned_henikoff_sort.bam" \
OUTPUT="${dupmarkdir}/${sample}_henikoff_dupmark.bam" \
METRICS_FILE="${logdir}/${sample}_henikoff_dupmark_metrics.txt"

picard MarkDuplicates \
INPUT="${aligndir}/${sample}_aligned_henikoff_sort.bam" \
OUTPUT="${dedupdir}/${sample}_henikoff_dedup.bam" \
METRICS_FILE="${logdir}/${sample}_henikoff_dedup_metrics.txt" \
REMOVE_DUPLICATES=true

######### FILTER BAM FILES TO READS UNDER 120bp #########

>&2 echo "Filtering to <120bp..."

samtools view -h "${dupmarkdir}/${sample}_henikoff_dupmark.bam" | awk -f $crtools/filter_below.awk | samtools view -Sb - > "${dupmarkdest}/${sample}_henikoff_dupmark_120bp.bam"
samtools view -h "${dedupdir}/${sample}_henikoff_dedup.bam" |awk -f $crtools/filter_below.awk | samtools view -Sb - > "${dedupdest}/${sample}_henikoff_dedup_120bp.bam"

>&2 echo "Creating bam index files... "
samtools index "${dupmarkdir}/${sample}_henikoff_dupmark.bam"
samtools index "${dedupdir}/${sample}_henikoff_dedup.bam"
samtools index "${dupmarkdest}/${sample}_henikoff_dupmark_120bp.bam"
samtools index "${dedupdest}/${sample}_henikoff_dedup_120bp.bam"

######### GET FRAGMENT LENGTHS FOR QC METRICS ###########

>&2 echo "Get Fragment length"

samtools view -F 0x04 "${aligndir}/${sample}_aligned_henikoff.sam" | awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print abs($9)}' | sort | uniq -c | awk -v OFS="\t" '{print $2, $1/2}' > "${logdir}/${sample}_henikoff_fragmentLen.txt"

samtools view -h -o "${dupmarkdest}/${sample}_dupmark_120bp.sam" "${dupmarkdest}/${sample}_henikoff_dupmark_120bp.bam"

samtools view -F 0x04 "${dupmarkdest}/${sample}_dupmark_120bp.sam" | awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print abs($9)}' | sort | uniq -c | awk -v OFS="\t" '{print $2, $1/2}' > "${logdir}/${sample}_henikoff_120bp_fragmentLen.txt"

rm "${dupmarkdest}/${sample}_dupmark_120bp.sam"

>&2 echo "Completed Script"

[[ -n "$JOB_ID" ]] && qstat -j "$JOB_ID"
