## aCUTRUN
This repository contains a pipeline to CUT&RUN analysis on individual samples and replicate samples. Scripts are derived from [CUT&RUNTools](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1802-4) and [CUT&TAG tutorial](https://www.protocols.io/view/cut-amp-tag-data-processing-and-analysis-tutorial-e6nvw93x7gmk/v1). Scripts are designed for UCSF's Wynton HPC.

## Software and Resources
Trimmomatic=0.36\
MACS2\
deeptools\
Kseq\
HOMER\
ChIPseeker (R package) install for r/4.4\
TxDb.Mmusculus.UCSC.mm10.knownGene (R package) install for r/4.4\
org.Mm.eg.db (R package) install for r/4.4

mm10 bowtie2 index (place in a folder called "mm10" in the resources folder: aCUTRUN/resources/mm10)\
mm10 gtf (place in the resources folder: aCUTRUN/resources)\
E.coli genome for spike-in (Epicypher spike-in)

# Individual Analysis
Requirements:
1) paired-end FASTQs in a project folder where the output from the pipeline will be directed
2) a samplesheet for the project in the same folder as the FASTQs
3) qsub the submit_cutandrun.sh from within the aCUTRUN folder.

Samplesheet:\
A .txt file where each line describes a sample to be analyzed.\
Each line contains: Project folder, Sample Name, Suffix of FASTQ1, Suffix of FASTQ2, Control Sample Name or "none"

Project Folder: The folder where you are storing the FASTQs and where the analysis output will be deposited\
Sample Name: The name of your sample, which is also the prefix on the FASTQ file\
Suffix of FASTQ1/2: The rest of the FASTQ filename after the sample name, usually indicating read, lane, etc.\
Control sample name: The control sample you would like to compare your sample to (i.e the IgG control in CUT&RUN experiments). If "none", sample vs control analysis will not be performed.\
Two example files are provided for two projects with two samples each:\
Project 1: CR48_test -  ```CR48_test_samples.txt``` in ```aCUTRUN/example_sheets/```\
Project 2: CR49_test - ```CR49_test_samples.txt``` in ```aCUTRUN/example_sheets/```

In preparation for replicate analysis, the Sample Name should include the project ID.\
For example: Project ID: CR48_test, Sample Name: CR48_test_Gli2_500.\
The replicates should also have matching sample names.\
For example: Replicate 1 Sample Name: CR48_test_Gli2_500, Replicate 2 Sample Name: CR49_test_Gli2_500.

## Individual analysis submission
Arguments: Full path to the samples.txt file

```
cd /path/to/aCUTRUN
qsub submit_cutandrun.sh /path/to/CR48_test_samples.txt
 ```

# Replicate Analysis
Requirements:
1) Individual analysis has been run on all samples
2) Project folders for each replicate are in the same base folder. For example: ```/path/to/base/CR48_test``` and ```/path/to/base/CR49_test```
3) Replicate samples have identical sample names after project ID. For example: CR48_test_Gli2_500 and CR49_test_Gli2_500
4) Individual samples have been compared to a corresponding control.
5) A Replicate folder containing the replicates.csv samplesheet has been created.

Samplesheet:\
A .csv file where each line describes replicates to be combined and analyzed.\
Each line contains: Replicate Folder, Sample Name (without project ID), Control Same Name (without project ID), Project ID replicate 1, Project ID replicate 1, ... Project ID replicate n.
 
Replicate Folder: The folder with the replicates.csv file and where the analysis output will be deposited\
Sample Name: The name of your sample, without the prefix project ID\
Control Sample Name: The name of the control sample that the Sample Name was compared, without the prefix project ID\
Project ID replicate 1: Project ID for first project\
Project ID replicate 2: Project ID for second project\
...\
Project ID replicate n: Project ID for nth project

An example file is provided for two projects with two samples each:\
```aCUTRUN/example_sheets/CR48_49_test_replicates.csv```

## Replicate analysis submission
Arguments: Full path to the replicates.csv file\
Full path to the folder containing the project folders for indvidiual projects.
```
cd /path/to/aCUTRUN
qsub submit_replicates.sh /path/to/base/CR48_49_test/CR48_49_test_replicates.csv /path/to/base/
```
# Accessory scripts
Example scripts for analyses such as Diffbind are included. They require information and design based on project goals. Scripts are provided as a guide.
