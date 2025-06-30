#!/bin/bash                         #-- what is the language of this shell
#                                  #-- Any line that starts with #$ is an instruction to SGE
#$ -S /bin/bash                     #-- the shell for the job
#$ -o /dev/null
#$ -cwd                            #-- tell the job that it should start in your working directory
#$ -r y                            #-- tell the system that if a job crashes, it should be restarted
#$ -j y                            #-- tell the system that the STDERR and STDOUT should be joined
#$ -l mem_free=50G
#$ -l scratch=10G
#$ -l h_rt=72:00:00

####### DEFINE ENVIRONMENT/MODULES ####
module load CBI bedtools2/2.30.0

###### DEFINE ARGUMENTS #####
sample=$1
project=$2
projdir=$3
PROJECT_ROOT=$4
LOG_DIR=$5

projPath="${projdir}/${sample}/"
dupdir=$projPath/dupmark/
dedupdir=$projPath/dedup/
chromSize="${PROJECT_ROOT}/tools/cutruntools/assemblies/chrom.mm10/mm10.chrom.sizes"
count=$(head -n 1 "$projPath"/logs/"$sample"_spikein_count.txt)

######## SET UP LOG FILE #########
# Redirect both stdout and stderr to the log file
LOG_FILE="${LOG_DIR}/calibrate_${JOB_ID}.log"
exec > "$LOG_FILE" 2>&1

#### Create normalized bedgraphs ####
if [[ "$count" -gt "1" ]]; then

    scale_factor=`echo "100000 / $count" | bc -l`
    echo "Scaling factor for $sample is: $scale_factor!"

    bedtools genomecov -bg \
	    -pc \
	    -scale $scale_factor \
	    -ibam "${dupdir}/${sample}_henikoff_dupmark_120bp.bam" > "${dupdir}/${sample}_henikoff_dupmark_120bp_fragments_normalized.bedgraph"	

    bedtools genomecov -bg \
            -pc \
            -scale $scale_factor \
            -ibam "${dedupdir}/${sample}_henikoff_dedup_120bp.bam" > "${dedupdir}/${sample}_henikoff_dedup_120bp_fragments_normalized.bedgraph" 
fi

bedtools genomecov -bg \
	-pc \
	-ibam "${dupdir}/${sample}_henikoff_dupmark_120bp.bam" > "${dupdir}/${sample}_henikoff_dupmark_120bp_fragments.bedgraph"

bedtools genomecov -bg \
        -pc \
        -ibam "${dedupdir}/${sample}_henikoff_dedup_120bp.bam" > "${dedupdir}/${sample}_henikoff_dedup_120bp_fragments.bedgraph"

#### Make scaled bigwigs ####
bamCoverage -b "${dupdir}/${sample}_henikoff_dupmark_120bp.bam" -o "${dupdir}/${sample}_henikoff_dupmark_120bp_scaled_${scale_factor}.bw" \
        --scaleFactor $scale_factor \
        --effectiveGenomeSize 2652783500 \
        --extendReads \
        --binSize 10


bamCoverage -b "${dedupdir}/${sample}_henikoff_dedup_120bp.bam"  -o "${dedupdir}/${sample}_henikoff_dedup_120bp_scaled_${scale_factor}.bw" \
        --scaleFactor $scale_factor \
        --effectiveGenomeSize 2652783500 \
        --extendReads \
        --binSize 10

