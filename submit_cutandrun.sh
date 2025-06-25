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


################## FASTQC #######################

#while IFS=, read project sample R1 R2 control;do
#        fastqc $workdir/$project/"$sample"_"$R1" $workdir/$project/"$sample"_"$R2"

#done < $file


################# TRIMMING ############

while IFS=, read project sample R1 R2 control;do
	fastq1=$workdir/"$sample"_"$R1"
	fastq2=$workdir/"$sample"_"$R2"
	qsub -N trim_"$project"_"$sample" $script_dir/trim_backup.sh $project $sample "$fastq1" "$fastq2" $workdir $PROJECT_ROOT $LOG_DIR
done < $file

################## ALIGNMENT ##################3
while IFS=, read project sample R1 R2 control;do
	qsub -hold_jid trim_"$project"_"$sample" -N align_"$project"_"$sample" $script_dir/align_dup_filter.sh $project $sample $workdir $PROJECT_ROOT $LOG_DIR
done < $file


################ BAMTOBIGWIG #################
while IFS=, read project sample R1 R2 control;do
	qsub -hold_jid align_"$project"_"$sample" -N bamtobigwig_"$project"_"$sample" $script_dir/bamtobigwig_RPGC.sh $project $sample $tmp $PROJECT_ROOT $LOG_DIR
done < $file

################### Spike-in ALIGNMENT ##################
while IFS=, read project sample R1 R2 control;do
	## E.coli from homemade pA-MNase
	#qsub -hold_jid trim_"$project"_"$sample" -N spikealign_"$project"_"$sample" $script_dir/align_ecoli2.sh $project $sample $tmp
	
	## Yeast spike-in from Henikoff lab
	#qsub -hold_jid trim_"$project"_"$sample" -N spikealign_"$project"_"$sample" $script_dir/align_yeast.sh $project $sample $tmp
	
	## E.coli spike-in from Epicypher
	qsub -hold_jid trim_"$project"_"$sample" -N spikealign_"$project"_"$sample" $script_dir/align_ecoliMG1655.sh $project $sample $tmp
	
	
	qsub -hold_jid spikealign_"$project"_"$sample" -N spikein_"$project"_"$sample" $script_dir/getSpikeIn.sh $sample $project $tmp
 	qsub -hold_jid spikein_"$project"_"$sample",align_"$project"_"$sample" -N calibrate_"$project"_"$sample" $script_dir/calibrate_bedgraph.sh $sample $project $tmp
done < $file


################## PEAK CALLING #######################

while IFS=, read project sample R1 R2 control;do
	
	if [ "$control" != "none" ]; then
		>&2 echo "Running peaking calling with control samples"
		qsub -hold_jid "align_*" -N macs2_"$project"_"$sample" $script_dir/macs2_peaks.sh $project $sample $tmp $PROJECT_ROOT $LOG_DIR $control
		
		
	else
		>&2 echo "Running peak calling without control samples"
		qsub -hold_jid align_"$project"_"$sample" -N macs2_"$project"_"$sample" $script_dir/macs2_peaks.sh $project $sample $tmp $PROJECT_ROOT $LOG_DIR
	fi
done < $file

################# BLACKLISTED REGIONS  ############

while IFS=, read project sample R1 R2 control;do
	>&2 echo "removing blacklist from '$sample' peaks"
                peak1=$workdir/"$sample"/MACS2_dedup/"$sample"_dedup_peaks.narrowPeak
                peak2=$workdir/"$sample"/MACS2_dupmark/"$sample"_dupmark_peaks.narrowPeak
                qsub -hold_jid macs2_"$project"_"$sample" -N blacklist_"$sample"_dedup $script_dir/blacklist.sh $peak1 $PROJECT_ROOT $LOG_DIR
                qsub -hold_jid macs2_"$project"_"$sample" -N blacklist_"$sample"_dupmark $script_dir/blacklist.sh $peak2 $PROJECT_ROOT $LOG_DIR
        if [ "$control" != "none" ]; then
                >&2 echo "removing blacklist from '$sample'_vs_"$control" peaks"
                peak3=$workdir/"$sample"_vs_"$control"/MACS2_dedup/"$sample"_vs_"$control"_dedup_peaks.narrowPeak
                peak4=$workdir/"$sample"_vs_"$control"/MACS2_dupmark/"$sample"_vs_"$control"_dupmark_peaks.narrowPeak
                qsub -hold_jid macs2_"$project"_"$sample" -N blacklist_"$sample"_vs_"$control"_dedup $script_dir/blacklist.sh $peak3 $PROJECT_ROOT $LOG_DIR
                qsub -hold_jid macs2_"$project"_"$sample" -N blacklist_"$sample"_vs_"$control"_dupmark $script_dir/blacklist.sh $peak4 $PROJECT_ROOT $LOG_DIR
        else
                >&2 echo "no control"
        fi
done < $file

################# CHIPSEEKER  ############
while IFS=, read project sample R1 R2 control;do
	qsub -hold_jid blacklist_"$sample"_dedup -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/$sample/MACS2_dedup/"$sample"_dedup_peaks_blklist.bed
        qsub -hold_jid blacklist_"$sample"_dupmark -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/$sample/MACS2_dupmark/"$sample"_dupmark_peaks_blklist.bed

        if [ "$control" != "none" ]; then
        qsub -hold_jid blacklist_"$sample"_vs_"$control"_dedup -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/"$sample"_vs_"$control"/MACS2_dedup/"$sample"_vs_"$control"_dedup_peaks_blklist.bed
        qsub -hold_jid blacklist_"$sample"_vs_"$control"_dupmark -N chpsk_"$sample" $script_dir/chpskr_general.sh $workdir/"$sample"_vs_"$control"/MACS2_dupmark/"$sample"_vs_"$control"_dupmark_peaks_blklist.bed

        else
                >&2 echo "no control"   
        fi

done < $file




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


################ GET METRICS AND COPY RESULTS ##################
qsub -hold_jid "calibrate*" -N metrics $script_dir/sub_metrics.sh $file $workdir
#qsub -hold_jid "seacr*","chpskr*" $script_dir/copy.sh $project $tmp

