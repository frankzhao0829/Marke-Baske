library("arules")
library("arulesSequences")
library("stringr")

# Set working directory of the subproduct data
setwd("C:/Users/TBD")

# Load the subproduct data
subproduct <- read.csv(file = 'subproduct_input_data.csv', header = TRUE, stringsAsFactor=FALSE, 
                       col.names = c("sequenceID", "eventID", "Product"),strip.white=TRUE)


# Transpose the data and combine products that pruchased at same date
trans <- as(split(subproduct[,"Product"],
            paste(subproduct[,"sequenceID"],subproduct[,"eventID"],sep=",")),"transactions")
trans.df <- as(trans, 'data.frame')
trans.df <- data.frame(trans.df$items,str_split_fixed(trans.df$transactionID, ",", 2),
                       stringsAsFactors=FALSE)
colnames(trans.df) <- c("items", "sequenceID","eventID")
trans.df$items <- as.character(trans.df$items)
trans.df$eventID <- as.Date(trans.df$eventID, "%m/%d/%Y")
trans.df <- trans.df[order(trans.df$sequenceID,trans.df$eventID),]

# Create a new EventID column - change timestamp to an ID for arulesSequence to work
trans.df$eventID2 <- as.factor(with(trans.df, ave(sequenceID, sequenceID, FUN = seq_along)))
trans.df$sequenceID <- as.factor(trans.df$sequenceID)
trans.df$items <- as.factor(trans.df$items)

# Select required columns
trans.df.subset <- trans.df[ , c('sequenceID', 'eventID2', 'items')]

trans.df.subset$items <- gsub("\\{","",trans.df.subset$items)
trans.df.subset$items <- gsub("\\}","",trans.df.subset$items)

#trans.test <- as(trans.df.subset,"transactions")
write.table(x = trans.df.subset, file = 'trans.df.txt', sep = ',', row.names = FALSE, 
            col.names = FALSE, quote = FALSE)

# Read transactions file
transactions <- read_baskets(con='trans.df.txt', sep=',', info=c("sequenceID","eventID"))

# Set minimum support threshold valueand generate Sequential Patterns using CSPADE
sequence.data <- cspade(transactions, parameter=list(support=0.05,maxsize=50,maxlen=50), 
                        control=list(verbose = TRUE))
sequence.data

rules <- ruleInduction(sequence.data, confidence = 0.01)
rules <- subset(rules, subset = lift > 1.01)
rules

#Find mixed EG, SW rules
rules.mixed <- subset(rules, (lhs(x) %pin% c("\\(SW)") & rhs(x) %pin% c("\\(EG)"))
                            |(lhs(x) %pin% c("\\(EG)") & rhs(x) %pin% c("\\(SW)")))
rules.mixed

# Prune redundant rules
quality(rules.mixed) <- round(quality(rules.mixed), digits=3)
rules.sequences <- as(rules.mixed,"sequences")
inspect(head(rules.sequences))

subset.matrix <- is.subset(rules.sequences, rules.sequences)
#subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
diag(subset.matrix) <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1

# remove redundant rules
rules.pruned <- rules.mixed[!redundant]
rules.pruned 

# Convert the rules to a data frame
rules.df <- as(rules.pruned, 'data.frame')
rules.df <- rules.df[order(-rules.df[,4]),]
write.csv(rules.df, file= "path_TBD/rules_description_TBD_out.csv", row.names=FALSE)

