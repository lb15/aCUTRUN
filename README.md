## aCUTRUN
This repository contains a pipeline to CUT&RUN analysis on individual samples and replicate samples. Scripts are derived from [CUT&RUNTools](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1802-4) and [CUT&TAG tutorial](https://www.protocols.io/view/cut-amp-tag-data-processing-and-analysis-tutorial-e6nvw93x7gmk/v1). Scripts are designed for UCSF's Wynton HPC.

## Software and Resources
Trimmomatic=0.36
MACS2
deeptools
Kseq
HOMER
ChIPseeker (R package) install for r/4.4
TxDb.Mmusculus.UCSC.mm10.knownGene (R package) install for r/4.4
org.Mm.eg.db (R package) install for r/4.4

mm10 bowtie2 index (place in a folder called "mm10" in the resources folder: aCUTRUN/resources/mm10)
mm10 gtf (place in the resources folder: aCUTRUN/resources)
E.coli genome for spike-in (Epicypher spike-in)

## Individual Analysis
Requirements:
1) paired-end FASTQs in a project folder where the output from the pipeline will be directed
2) a samplesheet for the project in the same folder as the FASTQs
3) qsub the submit_cutandrun.sh from within the aCUTRUN folder.

Samplesheet:
A .txt file where each line describes a sample to be analyzed.
Each line contains: Project folder, Sample name, Suffix of FASTQ1, Suffix of FASTQ2, Control sample name (optional)

Project Folder: The folder where you are storing the FASTQs and where the analysis output will be deposited
Sample Name: The name of your sample, which is also the prefix on the FASTQ file
Suffix of FASTQ1/2: The rest of the FASTQ filename after the sample name, usually indicating read, lane, etc.
Control sample name: The control sample you would like to compare your sample to (i.e the IgG control in CUT&RUN experiments). If left blank, sample vs control analysis will not be performed.
An example file is provided and named CR48_test_samples.txt in aCUTRUN/example_sheets/

In preparation for replicate analysis, the Sample Name should include the project ID. 
For example: Project ID: CR48_test, Sample Name: CR48_test_Gli2_500. 
The replicates should also have matching sample names. 
For example: Replicate 1 Sample Name: CR48_test_Gli2_500, Replicate 2 Sample Name: CR49_test_Gli2_500.

# Individual analysis submission
```
cd /path/to/aCUTRUN
qsub submit_cutandrun.sh /path/to/CR48_test_sample.txt
 ```
