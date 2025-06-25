#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=20G
#$ -l scratch=10G
#$ -l h_rt=72:00:00
#$ -m ea                           #--email when done
#$ -pe smp 4

######### LOAD ENVIRONMENT AND MODULES ########

source /wynton/home/reiter/lb13/miniconda3/bin/activate CutRun

module load CBI bowtie2/2.4.2 samtools/1.10

######## DEFINE ARGUMENTS #########

project=$1
sample=$2
fastq1=$3
fastq2=$4
projdir=$5
PROJECT_ROOT=$6
LOG_DIR=$7

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/trim_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

######## SET UP $TMPDIR DIRECTORY FOR SPEED #########
if [[ -z "$TMPDIR" ]]; then
  if [[ -d /scratch ]]; then TMPDIR=/scratch/$USER; else TMPDIR=/tmp/$USER; fi
  mkdir -p "$TMPDIR"
  export TMPDIR
fi

cd $TMPDIR

workdir=$TMPDIR/$project/$sample/
trimdir=$workdir/trimmomatic

mkdir -p $workdir
mkdir -p $trimdir

######## SET UP TOOLS DIRECTORY ######
crtools=$PROJECT_ROOT/tools/cutruntools/

######## SET UP DESTINATION DIRECTORY #######

destdir=$projdir/$sample/trimmomatic
logdir=$projdir/$sample/logs

mkdir -p $destdir
mkdir -p $logdir

######## DETECT READ LENGTH AND RECORD #######
bp=$(zcat $fastq1 | awk 'NR % 4 == 2 { print length($0); exit }')

echo "${project} : ${sample} : Detected read length: ${bp}" > "${logdir}/ReadLengths.txt"

######## TRIMMOMATIC ##########
echo >&2  "Trimming file $sample ..."

trimmomatic PE -threads "${NSLOTS:-1}" -phred33 -trimlog $logdir/trimlog.txt $fastq1 $fastq2 $trimdir/"$sample"_1.paired.fastq.gz $trimdir/"$sample"_1.unpaired.fastq.gz $trimdir/"$sample"_2.paired.fastq.gz $trimdir/"$sample"_2.unpaired.fastq.gz ILLUMINACLIP:$crtools/adapters/Truseq3.PE.fa:2:15:4:4:true LEADING:20 TRAILING:20 SLIDINGWINDOW:4:15 MINLEN:25

echo >&2 "Second stage trimming $sample ..."

$crtools/kseq_test $trimdir/"$sample"_1.paired.fastq.gz $bp $trimdir/"$sample"_1_kseq_paired.fastq.gz
$crtools/kseq_test $trimdir/"$sample"_2.paired.fastq.gz $bp $trimdir/"$sample"_2_kseq_paired.fastq.gz

echo >&2 "K-seq trimming complete"

echo >&2 "Copying files"

cp $trimdir/"$sample"_1.paired.fastq.gz $destdir/
cp $trimdir/"$sample"_2.paired.fastq.gz $destdir/
cp $trimdir/"$sample"_1_kseq_paired.fastq.gz $destdir/trimmomatic/
cp $trimdir/"$sample"_2_kseq_paired.fastq.gz $destdir/trimmomatic/
