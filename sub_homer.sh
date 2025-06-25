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
LOG_DIR=$workdir/log_reiter_cutandrun
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/reiter_cutandrun_${JOB_ID}.log"

# Redirect both stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

echo >&2 "Sample Information file: ${file}"
echo >&2 "Base directory: ${tmp}"
echo >&2 "LOG Directory: ${LOG_FILE}"
echo >&2 "Script directory: ${PROJECT_ROOT}"
echo >&2 "Submitting modules"
echo >&2 "Conda environment being sourced: ${CONDA_ENV}"

############### HOMER MOTIF FINDING #################

genome=$PROJECT_ROOT/tools/homer/data/genomes/mm10/

while IFS=, read project sample R1 R2 control;do
        
	inputbed="${workdir}/${sample}/MACS2_dedup/${sample}_dedup_peaks_blklist.bed"
	qsub -hold_jid blacklist_"$sample"_dedup -N homer_"$project"_"$sample" $script_dir/homer.sh $inputbed $genome 50 $LOG_DIR

	inputbed2="${workdir}/${sample}/MACS2_dupmark/${sample}_dupmark_peaks_blklist.bed"
	qsub -hold_jid blacklist_"$sample"_dupmark -N homer_dups_"$project"_"$sample" $script_dir/homer.sh $inputbed2 $genome 50 $LOG_DIR
	
	if [ "$control" != "none" ]; then

        	>&2 echo "running '$sample'_vs_'$control' analysis"
               
                inputbed3="${workdir}/${sample}_vs_${control}/MACS2_dedup/${sample}_vs_${control}_dedup_peaks_blklist.bed"
                qsub -hold_jid blacklist_"$sample"_vs_"$control"_dedup -N homer_control_dedup_"$project"_"$sample" $script_dir/homer.sh $inputbed3 $genome 50 $LOG_DIR

		inputbed4="${workdir}/${sample}_vs_${control}/MACS2_dupmark/${sample}_vs_${control}_dupmark_peaks_blklist.bed"
		qsub -hold_jid blacklist_"$sample"_vs_"$control"_dupmark -N homer_control_dupmark_"$project"_"$sample" $script_dir/homer.sh $inputbed4 $genome 50 $LOG_DIR
        else
		>&2 echo "no control run"

        fi
done < $file

