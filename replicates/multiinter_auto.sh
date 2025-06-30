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

######### DEFINE ENVIRONMENT/MODULES ######

module load CBI bedtools2/2.30.0

######## DEFINE ARGUMENTS ######
input_file=$1
output_name=$2
LOG_DIR=$3

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/multiinter_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

######## SET REPLICATE NUMBER THRESHOLD ######
num_files=$(wc -l < "$input_file")
### Set reps dynamically
if [ "$num_files" -eq 3 ]; then
    reps=2
elif [ "$num_files" -eq 4 ]; then
    reps=3
else
    echo "Warning: Number of input files ($num_files) doesn't match expected cases (3 or 4). Defaulting to reps=2."
    reps=2  # Default value if conditions are not met
fi

echo >&2 "Using reps=$reps"

xargs -a $input_file bedtools multiinter -header -i > "$output_name".txt
awk -v thresh="$reps" '$4 >= thresh {print}' "$output_name".txt > "$output_name"_filter.bed
echo "$(tail -n +2 "$output_name"_filter.bed)" > "$output_name"_filter_nohead.bed

sort -k1,1 -k2,2n -k3,3n "$output_name"_filter_nohead.bed > "$output_name"_sort.bed
cat "$output_name"_sort.bed | awk '{print $1"\t"$2"\t"$3}'| bedtools merge -i - > "$output_name"_replicates.bed

rm "$output_name"_filter.bed
rm "$output_name"_filter_nohead.bed
rm "$output_name"_sort.bed


### run bedtools map to add back signalValue

for rep in $(cat $input_file); do
    bedtools map -a "$output_name"_replicates.bed -b "$rep" -c 7 -o mean > "$output_name"_replicates_scored.bed
done

## add unique ID to fourth column
file_name=${output_name##*/}
awk -v name="$file_name" 'BEGIN {OFS="\t"} {print $1, $2, $3, name "_Peak_" NR, $4}' "$output_name"_replicates_scored.bed > "$output_name"_replicates_homID.bed

#awk '{print $0 "\t.\t."}' "$output_name"_replicates.bed > "$output_name"_replicates_hom.bed
echo >&2 "Finished"
