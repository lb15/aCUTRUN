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
LOG_FILE="${LOG_DIR}/sub_macs2_${JOB_ID}.log"

# Redirect both stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

echo >&2 "Sample Information file: ${file}"
echo >&2 "Base directory: ${workdir}"
echo >&2 "LOG Directory: ${LOG_FILE}"
echo >&2 "Script directory: ${PROJECT_ROOT}"
echo >&2 "Submitting modules"

################## PEAK CALLING #######################

while IFS=, read project sample R1 R2 control;do
	
	if [ "$control" != "none" ]; then
		>&2 echo "Running peaking calling with control samples"
		qsub -hold_jid "align_*" -N macs2_"$project"_"$sample" $script_dir/macs2_peaks.sh $project $sample $workdir $PROJECT_ROOT $LOG_DIR $control
		
		
	else
		>&2 echo "Running peak calling without control samples"
		qsub -hold_jid align_"$project"_"$sample" -N macs2_"$project"_"$sample" $script_dir/macs2_peaks.sh $project $sample $workdir $PROJECT_ROOT $LOG_DIR
	fi
done < $file

