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
LOG_FILE="${LOG_DIR}/sub_replicates_${JOB_ID}.log"

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

################## MAKE PEAK LISTS TO INTERSECT #######################
>&2 echo "Making peak lists"

while IFS=, read -r first_arg rest_of_line; do
	name=$first_arg

	### make folder for combined replicates for each sample
	IFS=',' read -r -a args <<< "$rest_of_line"
	sample=${args[0]}
	control=${args[1]}
	sampleoutdir="${outputdir}/${sample}_vs_${control}"
	mkdir -p $sampleoutdir
	mkdir "${sampleoutdir}/dupmark"
        mkdir "${sampleoutdir}/dedup"

	echo >&2 "Project: ${name}: Sample: ${sample}"

	### Check if peak list files exist, and if they do, delete them
	duplist="${sampleoutdir}/dupmark/${sample}_vs_${control}_dupmark_peak_list.txt"
	deduplist="${sampleoutdir}/dedup/${sample}_vs_${control}_dedup_peak_list.txt"

	if [ -f "$duplist" ]; then
    		rm "$duplist"
    		echo "Deleted: $duplist"
	fi

	if [ -f "$deduplist" ]; then
    		rm "$deduplist"
    		echo "Deleted: $deduplist"
	fi


	for ((i=2; i<${#args[@]}; i++)); do
		dup_file=$workdir/${args[$i]}/"${args[$i]}"_"$sample"_vs_"${args[$i]}"_"$control"/MACS2_dupmark/"${args[$i]}"_"$sample"_vs_"${args[$i]}"_"$control"_dupmark_peaks_blklist.bed
		dedup_file=$workdir/${args[$i]}/"${args[$i]}"_"$sample"_vs_"${args[$i]}"_"$control"/MACS2_dedup/"${args[$i]}"_"$sample"_vs_"${args[$i]}"_"$control"_dedup_peaks_blklist.bed

		## append peak list from each replicate sample
		echo $dup_file >> "${duplist}"
		echo $dedup_file >> "${deduplist}"
	done
done < $file


########### RUN MULTIINTER TO COUNT REPLICATE PEAKS ##########

>&2 echo "Running Multiinter"

while IFS=, read -r name sample control rest_of_line; do
	sampleoutdir="${outputdir}/${sample}_vs_${control}"
	samplelist_dup="${sampleoutdir}/dupmark/${sample}_vs_${control}_dupmark_peak_list.txt"
	samplelist_dedup="${sampleoutdir}/dedup/${sample}_vs_${control}_dedup_peak_list.txt"
	outputfile_dup="${sampleoutdir}/dupmark/${sample}_vs_${control}_dupmark_multiinter"
	outputfile_dedup="${sampleoutdir}/dedup/${sample}_vs_${control}_dedup_multiinter"

	qsub -N "${name}_${sample}_${control}_multiinter_dupmark" \
		$script_dir/multiinter_auto.sh \
		$samplelist_dup \
		$outputfile_dup \
		$LOG_DIR
	
	qsub -N "$name"_"$sample"_"$control"_multiinter_dedup \
		$script_dir/multiinter_auto.sh \
		$samplelist_dedup \
		$outputfile_dedup \
		$LOG_DIR


	###### REMOVE PROBLEMATIC REGIONS ###############
	qsub -N "problem_dup_${name}_${sample}_${control}" \
		-hold_jid "${name}_${sample}_${control}_multiinter_dupmark" \
		$script_dir/problemregions_subtract.sh "${outputfile_dup}_replicates_homID.bed" \
		$PROJECT_ROOT \
		$LOG_DIR

	qsub -N "problem_dedup_${name}_${sample}_${control}" \
		-hold_jid "${name}_${sample}_${control}_multiinter_dedup" \
		$script_dir/problemregions_subtract.sh "${outputfile_dedup}_replicates_homID.bed" \
		$PROJECT_ROOT \
		$LOG_DIR

	############## CHIPSEEKER AND HOMER ################

	echo >&2 "Running chipseeker and homer"
	output_dup="${outputfile_dup}_replicates_homID_noprob.bed"
	output_dedup="${outputfile_dedup}_replicates_homID_noprob.bed"

	qsub -hold_jid "problem_dup_${name}_${sample}_${control}" \
		"${PROJECT_ROOT}/modules/chpskr_general.sh" \
		"${output_dup}" \
		"${PROJECT_ROOT}" \
		"${LOG_DIR}"

	qsub -hold_jid "problem_dedup_${name}_${sample}_${control}" \
		"${PROJECT_ROOT}/modules/chpskr_general.sh" \
		"${output_dedup}" \
		"${PROJECT_ROOT}" \
                "${LOG_DIR}"

	qsub -hold_jid "problem_dup_${name}_${sample}_${control}" \
		"${PROJECT_ROOT}/modules/homer.sh" \
		"${output_dup}" mm10 50 \
		"${PROJECT_ROOT}" \
		"${LOG_DIR}"

	qsub -hold_jid "problem_dup_${name}_${sample}_${control}" \
		"${PROJECT_ROOT}/modules/homer_annotatepeaks.sh" \
		"${output_dup}" mm10 homeranno \
		"${PROJECT_ROOT}" \
		"${LOG_DIR}"

	qsub -hold_jid "problem_dedup_${name}_${sample}_${control}" \
		"${PROJECT_ROOT}/modules/homer.sh" \
		"${output_dedup}" mm10 50 \
		"${PROJECT_ROOT}" \
		"${LOG_DIR}"
	
	qsub -hold_jid "problem_dedup_${name}_${sample}_${control}" \
		"${PROJECT_ROOT}/modules/homer_annotatepeaks.sh" \
		"${output_dedup}" mm10 homeranno \
		"${PROJECT_ROOT}" \
		"${LOG_DIR}"

	echo >&2 "Finished"
done < $file

############ MAKE CONSENSUS PEAK LISTS ############
echo >&2 "Making consensus peak list for entire project"

qsub -N "consensus_${name}" \
	-hold_jid "problem_*" \
	"${script_dir}/consensus_peaks_nogreylist.sh" $file $workdir $PROJECT_ROOT $LOG_DIR

##################### MAKE AVERAGE BIGWIGS #########################
echo >&2 "Averaging bigwigs"

while IFS=, read -r first_arg rest_of_line; do
        name=$first_arg

        IFS=',' read -r -a args <<< "$rest_of_line"
        sample=${args[0]}
        control=${args[1]}
        echo "Sample: $sample"

	samdup="${outputdir}/${sample}/dupmark/"
	samdedup="${outputdir}/${sample}/dedup/"
	condup="${outputdir}/${control}/dupmark/"
	condedup="${outputdir}/${control}/dedup/"
	
	mkdir -p $samdup
	mkdir -p $samdedup
	mkdir -p $condup
	mkdir -p $condedup

	### Check if peak list files exist, and if they do, delete them
        samduplist="${samdup}/${sample}_dupmark_bigwig_list.txt"
	samdeduplist="${samdedup}/${sample}_dedup_bigwig_list.txt"
	conduplist="${condup}/${control}_dupmark_bigwig_list.txt"
	condeduplist="${condedup}/${control}_dedup_bigwig_list.txt"

        if [ -f "$samduplist" ]; then
                rm "$samduplist"
                echo "Deleted: $samduplist"
        fi

        if [ -f "$samdeduplist" ]; then
                rm "$samdeduplist"
                echo "Deleted: $samdeduplist"
        fi

	if [ -f "$conduplist" ]; then
                rm "$conduplist"
                echo "Deleted: $conduplist"
        fi

        if [ -f "$condeduplist" ]; then
                rm "$condeduplist"
                echo "Deleted: $condeduplist"
        fi

        for ((i=2; i<${#args[@]}; i++)); do
		s_dup_file=$workdir/${args[$i]}/"${args[$i]}"_"$sample"/dupmark/"${args[$i]}"_"$sample"_henikoff_dupmark_120bp_RPGC.bw
		s_dedup_file=$workdir/${args[$i]}/"${args[$i]}"_"$sample"/dedup/"${args[$i]}"_"$sample"_henikoff_dedup_120bp_RPGC.bw
		c_dup_file=$workdir/${args[$i]}/"${args[$i]}"_"$control"/dupmark/"${args[$i]}"_"$control"_henikoff_dupmark_120bp_RPGC.bw
		c_dedup_file=$workdir/${args[$i]}/"${args[$i]}"_"$control"/dedup/"${args[$i]}"_"$control"_henikoff_dedup_120bp_RPGC.bw

                echo $s_dup_file >> $samduplist
                echo $s_dedup_file >> $samdeduplist
		echo $c_dup_file >> $conduplist
		echo $c_dedup_file >> $condeduplist
        done
done < $file

while IFS=, read -r name sample control rest_of_line; do
	dir_s_dup="${outputdir}/${sample}/dupmark/"
	dir_s_dedup="${outputdir}/${sample}/dedup/"
	dir_c_dup="${outputdir}/${control}/dupmark/"
	dir_c_dedup="${outputdir}/${control}/dedup/"

	qsub $script_dir/bigwigAverage_auto.sh \
		"${dir_s_dup}/${sample}_dupmark_bigwig_list.txt" \
		"${dir_s_dup}/${name}_${sample}_dupmark_avg_120bp_RPGC.bw" \
		"${LOG_DIR}"

	qsub $script_dir/bigwigAverage_auto.sh \
		"${dir_s_dedup}/${sample}_dedup_bigwig_list.txt" \
		"${dir_s_dedup}/${name}_${sample}_dedup_avg_120bp_RPGC.bw" \
		"${LOG_DIR}"

	qsub $script_dir/bigwigAverage_auto.sh \
		"${dir_c_dup}/${control}_dupmark_bigwig_list.txt" \
		"${dir_c_dup}/${name}_${control}_dupmark_avg_120bp_RPGC.bw" \
		"${LOG_DIR}"

	qsub $script_dir/bigwigAverage_auto.sh \
		"${dir_c_dedup}/${control}_dedup_bigwig_list.txt" \
		"${dir_c_dedup}/${name}_${control}_dedup_avg_120bp_RPGC.bw" \
		"${LOG_DIR}"
done < $file


