#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l h_rt=72:00:00


######### INPUTS ########
### Full path to a csv file with each line containing the following info:
### Project directory,sample,control,projectID for rep 1, projectID for rep 2, etc...
### The output from this pipeline will be placed in the same folder as this file.

### Full path to the folder where all the replicate project folders are located.

########## DEFINE ARGUMENTS #######
file=$1
workdir=$2
outputdir="${file%/*}" 

PROJECT_ROOT="$SGE_O_WORKDIR"
script_dir="${PROJECT_ROOT}/replicates/"

## LOG directory
LOG_DIR="${outputdir}/log_${JOB_ID}_cr_replicates"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/sub_consensus_${JOB_ID}.log"

# Redirect both stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

echo >&2 "Sample Information file: ${file}"
echo >&2 "Base directory: ${workdir}"
echo >&2 "Output directory: ${outputdir}"
echo >&2 "LOG Directory: ${LOG_FILE}"
echo >&2 "Script directory: ${PROJECT_ROOT}"
echo >&2 "Submitting modules"

##################### DEFINE GLOBAL VARIABLES #####################
pval=0.99

########################### LOAD MODULES  #################################
module load CBI bedtools2/2.30.0

############ MAKE CONSENSUS PEAK LISTS ############
echo >&2 "Making consensus peak list for entire project"

qsub -N "consensus_${name}" \
	-hold_jid "*_multiinter_*" \
	"${script_dir}/consensus_peaks_nogreylist.sh" $file $workdir $PROJECT_ROOT $LOG_DIR


