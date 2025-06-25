#### LOAD LIBRARIES ####
library(ChIPseeker)
library(TxDb.Mmusculus.UCSC.mm10.knownGene)
txdb=TxDb.Mmusculus.UCSC.mm10.knownGene

#### DEFINE ARGUMENTS ####
args = commandArgs(trailingOnly=TRUE)

outdir = args[1]
peak_file=args[2]
filename=args[3]

if(grepl("/",peak_file)){
	peak=readPeakFile(peak_file)
}else{
	peak=readPeakFile(paste0(outdir,"/",peak_file))
}
setwd(outdir)

#### DEFINE PROMOTERS ####
promoter <- getPromoters(TxDb=txdb, upstream=3000, downstream=3000)

#### ANNOTATE PEAKS ####
peakAnno <- annotatePeak(peak, tssRegion=c(-3000, 3000),
                         TxDb=txdb, annoDb="org.Mm.eg.db",addFlankGeneInfo=T, flankDistance=5000)

#### MAKE PLOTS ####
pdf(paste0(filename,"_annoBar.pdf"))
plotAnnoBar(peakAnno)
dev.off()

#### ADD GENE SYMBOLS ####
annotations_orgDb <- AnnotationDbi::select(org.Mm.eg.db, # database
                                           keys = keys(org.Mm.eg.db),  # data to use for retrieval
                                           columns = c("SYMBOL", "ENTREZID","GENENAME") # information to retreive for given data
                                           )
ens_flanks = peakAnno@anno$flank_geneIds
gene_flanks=list()
for(x in 1:length(ens_flanks)){
        if(is.na(ens_flanks[x])){
                gene_flanks[x]<-NA}
        else{
                gene_list=as.data.frame(strsplit(ens_flanks[x],";",fixed=T)[[1]])
                colnames(gene_list) <- c("GeneID")

                annotate_genes=annotations_orgDb$SYMBOL[match(gene_list$GeneID,annotations_orgDb$ENTREZID)]
                gene_flanks[[x]] <- paste(unique(annotate_genes),collapse = " ; ")

        }

}

peakAnno@anno$gene_flank_symbol <- gene_flanks

peaks_data=as.data.frame(peakAnno@anno)
peaks_data$gene_flank_symbol = unlist(peaks_data$gene_flank_symbol)

#### WRITE OUT RESULTS ####
write.csv(peaks_data,file=paste0(filename,"_chipseeker_peakannotations.csv"))

