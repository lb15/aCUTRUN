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
LOG_FILE="${LOG_DIR}/sub_spikein_${JOB_ID}.log"

# Redirect both stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

echo >&2 "Sample Information file: ${file}"
echo >&2 "Base directory: ${workdir}"
echo >&2 "LOG Directory: ${LOG_DIR}"
echo >&2 "Script directory: ${PROJECT_ROOT}"
echo >&2 "Submitting modules"


################### Spike-in ALIGNMENT ##################
while IFS=, read project sample R1 R2 control;do
	## E.coli from homemade pA-MNase
	#qsub -hold_jid trim_"$project"_"$sample" -N spikealign_"$project"_"$sample" $script_dir/align_ecoli2.sh $project $sample $tmp
	
	## Yeast spike-in from Henikoff lab
	#qsub -hold_jid trim_"$project"_"$sample" -N spikealign_"$project"_"$sample" $script_dir/align_yeast.sh $project $sample $tmp
	
	## E.coli spike-in from Epicypher
	qsub -hold_jid trim_"$project"_"$sample" -N spikealign_"$project"_"$sample" $script_dir/align_ecoliMG1655.sh $project $sample $workdir $PROJECT_ROOT $LOG_DIR
	
	
	qsub -hold_jid spikealign_"$project"_"$sample" -N spikein_"$project"_"$sample" $script_dir/getSpikeIn.sh $sample $project $workdir $PROJECT_ROOT $LOG_DIR
 	qsub -hold_jid spikein_"$project"_"$sample",align_"$project"_"$sample" -N calibrate_"$project"_"$sample" $script_dir/calibrate_bedgraph.sh $sample $project $workdir $PROJECT_ROOT $LOG_DIR
done < $file

