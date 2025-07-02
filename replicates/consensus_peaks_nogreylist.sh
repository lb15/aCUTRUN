#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=10G
#$ -l scratch=10G
#$ -l h_rt=24:00:00

################# LOAD ENVIRONMENT/MODULES #######

module load CBI bedtools2/2.30.0 samtools

##################### INPUTS ########################

## replicates csv file listing project name, sample, control, and replicates
file=$1
dir=$2
PROJECT_ROOT=$3
LOG_DIR=$4

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/consensus_peaks_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

############## CHECK IF CONSENSUS LIST FILE EXISTS ########

### remove consensus peak file in case it is there from a previous run
name=$(cut -d',' -f1 $file | sort | uniq)


if [ -e "${dir}/${name}/${name}_dupmark_consensus_peaks.bed" ]; then
	echo >&2 "removing existing consensus peak file"
	rm "${dir}/${name}/${name}_dupmark_consensus_peaks.bed"
fi

if [ -e "${dir}/${name}/${name}_dedup_consensus_peaks.bed" ]; then
	echo >&2 "removing existing consensus peak file"
	rm "${dir}/${name}/${name}_dedup_consensus_peaks.bed"
fi

#### concatenate peak files from all samples (vs. controls)

while IFS=, read -r name sample control rest_of_line; do
	peaks_dup="${dir}/${name}/${sample}_vs_${control}/dupmark/${sample}_vs_${control}_dupmark_multiinter_replicates_homID_noprob.bed"
	peaks_dedup="${dir}/${name}/${sample}_vs_${control}/dedup/${sample}_vs_${control}_dedup_multiinter_replicates_homID_noprob.bed"
	echo >&2 "Peaks to combine: ${peaks_dup}"

	cat "${peaks_dup}" >> "${dir}/${name}/${name}_dupmark_consensus_peaks.bed" 
	cat "${peaks_dedup}" >> "${dir}/${name}/${name}_dedup_consensus_peaks.bed" 
done < $file

name=$(cut -d',' -f1 $file | sort | uniq)
echo >&2 $name
basename_dup="${dir}/${name}/${name}_dupmark_consensus_peaks"
basename_dedup="${dir}/${name}/${name}_dedup_consensus_peaks"


##### SORT AND MERGE ######
sort -k1,1 -k2,2n "${basename_dup}.bed" > "${basename_dup}_sort.bed"
sort -k1,1 -k2,2n "${basename_dedup}.bed" > "${basename_dedup}_sort.bed"

perl -p -e 's/ /\t/g' "${basename_dup}_sort.bed" > "${basename_dup}_sort_tab.bed"
bedtools merge -i "${basename_dup}_sort_tab.bed" > "${basename_dup}_merged.bed"

rm "${basename_dup}_sort.bed"
rm "${basename_dup}_sort_tab.bed"

perl -p -e 's/ /\t/g' "${basename_dedup}_sort.bed" > "${basename_dedup}_sort_tab.bed"
bedtools merge -i "${basename_dedup}_sort_tab.bed" > "${basename_dedup}_merged.bed"

rm "${basename_dedup}_sort.bed"
rm "${basename_dedup}_sort_tab.bed"
