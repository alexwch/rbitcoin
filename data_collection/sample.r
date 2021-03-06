# Program: 
# get data from bitstamp.net on transactions 
# get market data from bitcoincharts
# Date Create: "2016-02-28"
# Date Last Modified: ""

# Source: http://www.r-bloggers.com/accessing-bitcoin-data-with-r/

library(RJSONIO)

url <- "https://www.bitstamp.net/api/transactions/"
bs_data <- fromJSON(url) # returns a list
bs_df <- do.call(rbind,lapply(bs_data,data.frame,stringsAsFactors=FALSE))
head(bs_df)

library(plyr)
bs_df2 <- ldply(bs_data,data.frame)

#In the data frame returned above
#"tid" is the transaction id 
#"date" is the time stamp of the transaction in unix time 
#"price" is the bitcoin price. "amount" the amount of bitcoin
#"type" = 0 for a buy and 1 for a sell



# Source: http://www.r-bloggers.com/querying-the-bitcoin-blockchain-with-r/

library(Rbitcoin)

wait <- antiddos(market = 'kraken', antispam_interval = 5, verbose = 1)
market.api.process('kraken',c('BTC','EUR'),'ticker')

trades <- market.api.process('kraken',c('BTC','EUR'),'trades')
Rbitcoin.plot(trades, col='blue')

wallet <- blockchain.api.process('15Mb2QcgF3XDMeVn6M7oCG6CQLw4mkedDi')
seed <- '1NfRMkhm5vjizzqkp2Qb28N7geRQCa4XqC'
genesis <- '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
singleaddress <- blockchain.api.query(method = 'Single Address', bitcoin_address = seed, limit=100)
txs <- singleaddress$txs

bc <- data.frame()
for (t in txs) {
        hash <- t$hash
        for (inputs in t$inputs) {
                from <- inputs$prev_out$addr
                for (out in t$out) {
                        to <- out$addr
                        va <- out$value
                        bc <- rbind(bc, data.frame(from=from,to=to,value=va, stringsAsFactors=F))
                }
        }
}

library(plyr)
btc <- ddply(bc, c("from", "to"), summarize, value=sum(value))

library(igraph)
btc.net <- graph.data.frame(btc, directed=T)
V(btc.net)$color <- "blue"
V(btc.net)$color[unlist(V(btc.net)$name) == seed] <- "red"
nodes <- unlist(V(btc.net)$name)
E(btc.net)$width <- log(E(btc.net)$value)/10
plot.igraph(btc.net, vertex.size=5, edge.arrow.size=0.1, vertex.label=NA, main=paste("BTC transaction network forn", seed))
