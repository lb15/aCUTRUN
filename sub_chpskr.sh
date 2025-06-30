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

########## DEFINE ARGUMENTS ##########

# file = full path to the required _samples.txt file with sample information. This file should be in same directory as FASTQs.

file=$1
workdir="${file%/*}"

PROJECT_ROOT="$SGE_O_WORKDIR"
script_dir="${PROJECT_ROOT}/modules/"

## LOG directory
LOG_DIR="${workdir}/log_${JOB_ID}_cutandrun"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/sub_chpskr_${JOB_ID}.log"

# Redirect both stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

echo >&2 "Sample Information file: ${file}"
echo >&2 "Base directory: ${tmp}"
echo >&2 "LOG Directory: ${LOG_FILE}"
echo >&2 "Script directory: ${PROJECT_ROOT}"
echo >&2 "Submitting modules"

################# CHIPSEEKER  ############
while IFS=, read project sample R1 R2 control;do
	qsub -hold_jid blacklist_"$sample"_dedup -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/$sample/dedup/MACS2_dedup/"$sample"_dedup_peaks_blklist.bed $PROJECT_ROOT $LOG_DIR
        qsub -hold_jid blacklist_"$sample"_dupmark -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/$sample/dupmark/MACS2_dupmark/"$sample"_dupmark_peaks_blklist.bed $PROJECT_ROOT $LOG_DIR

        if [ "$control" != "none" ]; then
        qsub -hold_jid blacklist_"$sample"_vs_"$control"_dedup -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/"$sample"_vs_"$control"/MACS2_dedup/"$sample"_vs_"$control"_dedup_peaks_blklist.bed $PROJECT_ROOT $LOG_DIR
        qsub -hold_jid blacklist_"$sample"_vs_"$control"_dupmark -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/"$sample"_vs_"$control"/MACS2_dupmark/"$sample"_vs_"$control"_dupmark_peaks_blklist.bed $PROJECT_ROOT $LOG_DIR

        else
                >&2 echo "no control"   
        fi

done < $file


