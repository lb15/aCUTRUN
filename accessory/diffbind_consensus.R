library(DiffBind)
library(stringi)

args = commandArgs(trailingOnly=TRUE)

file=args[1]
dir=args[2]
name=args[3]
peak_list=args[4]
dir.create(paste0(dir,"/consensus_nogrey_noprob/"))
save_dir=paste0(dir,"/consensus_nogrey_noprob/")

write.csv(args, file=paste0(save_dir,name,"_arguments.csv"))

sampleSheet <- read.csv(file, header=TRUE, stringsAsFactors=FALSE)
## read in my samplesheet
tamoxifen <- dba(sampleSheet=sampleSheet)


## import peak list, blacklist and greylists already applied.
consensus.peaks=read.table(peak_list,sep="\t",header=F)
head(consensus.peaks)

tamoxifen <- dba.count(tamoxifen,peaks=consensus.peaks)

print("normalizatoin")
tamoxifen <- dba.normalize(tamoxifen)
tamoxifen <- dba.contrast(tamoxifen,design=~Replicate + Treatment)
print("analyze")
tam1=tamoxifen
tam1 <- dba.analyze(tam1,bBlacklist=F,bGreylist=F)

saveRDS(tam1, file=paste0(save_dir,name,"_consensus.rds"))
