library(arules)
library(tcltk)

#setwd("C:/Users/zhaoch/Desktop")

#1. Import data from csv file
data.mkt <- read.table("Order_EG&SW_Combined_4-25-16.csv",header=T,sep=",") # Vertica SubPL level data

dim(data.mkt)
trans <- as(split(data.mkt[,"ItemType"], data.mkt[,"Order.No"]), "transactions")
inspect(head(trans))

#2. Run association rule algorithm for data
rules <- apriori(trans, parameter = list(minlen=2, supp=0.01, conf=0.1))
rules 
inspect(head(rules))

#3. Filter EG>SW or SW>EG rules
rules.mix <- subset(rules, subset=items %pin% "\\(SW)"&items %pin% "\\(EG)")
rules.mix

#4. Prune redundant rules
quality(rules.mix) <- round(quality(rules.mix), digits=3)
rules.sorted <- sort(rules.mix, by="lift")

inspect(head(rules.sorted))
subset.matrix <- is.subset(rules.sorted, rules.sorted)
subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1
#which(redundant)

# remove redundant rules
rules.pruned <- rules.sorted[!redundant]
rules.pruned <- subset(rules.pruned, subset = lift > 1.01)
rules.pruned

#export rules
write(rules.pruned, file = "../Order/rules/rules_EG&SW_Combined.csv"
      ,quote=TRUE, sep = ",", col.names = NA)

