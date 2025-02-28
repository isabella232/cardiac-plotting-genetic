
install.packages("data.table")
install.packages("circlize")

library(data.table)
library(circlize)

# load data for multiple linear regression analysis
multidata <- read.table("multiple_datatable.txt", header = TRUE)

beta_ml<-matrix(0,ncol=31, nrow=10)
mat_pv<-matrix(0,ncol=31, nrow=10)
t_BH<-matrix(0,ncol=31,1)
rsq<-matrix(0,ncol=31,1)
conflist<-vector(mode="list",length=31)

iT<-1
for (iN in 11:41){
  data_mul<-as.data.frame(multidata[,c(1:10,iN)])
  cv<-lapply(colnames(data_mul)[11], function(x) lm(formula(paste("`",x,"`","~.", sep="")),data=data_mul))
  pval<-summary(cv[[1]])$coefficients[,"Pr(>|t|)"] # get p-values
  p.cor<-p.adjust(pval,method = "BH") # adjust using Benjamini - Hochberg procedure
  names(p.cor)<-NULL
  beta<-as.vector(t(coef(cv[[1]], complete=TRUE)))[-1] # get beta coefficient
  t_BH[iT]<-get_bh_threshold(pval, 0.05) # get BH threshold
  smcv<-summary(cv[[1]])
  rsq[iT]<-smcv$r.squared # rsquared
  conflist[iT]<-list(confint(cv[[1]],level=0.95)[-1,]) # confidence intervals
  
  beta_ml[,iT]<-beta
  mat_pv[,iT]<-p.cor[-1]
  iT<-iT+1
}
# beta coefficients
colnames(beta_ml)<-colnames(multidata)[11:41]
rownames(beta_ml)<-colnames(multidata)[1:10]
# p-values
colnames(mat_pv)<-colnames(multidata)[11:41]
rownames(mat_pv)<-colnames(multidata)[1:10]

# prepare for the bubble plot

mt_Bh<-(-log10(mean(t_BH))) # BH threshold
colnames(mat_pv)<-c( "Strain rates","Strain rates","Strains",
                   "Strains","Strains", "LV", "AAo - DAo","AAo - DAo",
                   "AAo - DAo","AAo - DAo","AAo - DAo","AAo - DAo",
                   "LV","LV","LV","LV","LA","LA","LA","LV","LV","LV","LA","RV","RV",
                   "RV","RA","RA","RA","RV","RA")
multivar_b = chordDiagram(beta_ml) # beta coefficients
multivar_p = chordDiagram(mat_pv) # p-values
multivar_data<-cbind(multivar_p[,c(2,1,3)],multivar_b[,2:4]) # bind
colnames(multivar_data)<-c("Imaging_group","Nonimaging","LogP","Imaging","Beta", "AbsBeta")
multivar_data$AbsBeta<-abs(multivar_data$AbsBeta)
position_nonsig<-which(multivar_data$LogP<mt_Bh) # position of non significant
multivar_data$Imaging_group[position_nonsig]<-"Not significant"
write.table(multivar_data,"multivariable_analysis.txt",col.names = T, row.names = F)

# END
