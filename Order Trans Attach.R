library(arules)

# Set working directory of the data
setwd("C:/Users/zhaoch/Desktop/Project/Affinity Analysis/SW-ES/Order")

#1. Import data from csv file
data.mkt <- read.table("Order_TransAttach_SW_AMS.csv",header=T,sep=",")
trans <- as(split(data.mkt[,"ItemType"], data.mkt[,"Order.No"]), "transactions")

#2. Run association rule algorithm for data
rules <- apriori(trans, parameter = list(minlen=2, supp=0.01, conf=0.1))
rules 

#3. Prune redundant rules
quality(rules) <- round(quality(rules), digits=3)
rules.sorted <- sort(rules, by="lift")
subset.matrix <- is.subset(rules.sorted, rules.sorted)
subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1  #which(redundant)

  # remove redundant rules
rules.pruned <- rules.sorted[!redundant]
rules.pruned <- subset(rules.pruned, subset = lift > 1.01)
rules.pruned

#4.export rules
write(rules.pruned, file = "../Order/rules/rules_TransAttach_SW_AMS.csv"
      ,quote=TRUE, sep = ",", col.names = NA)

