# This code tests out a few of the functions in chromevolR
# it also illustrates the current problem of unknown states
# under the mkn framework as it currently is implemented.

library(devtools)
install_github('coleoguy/chromevolR')
library(chromevolR)
library(geiger)
library(diversitree)

########################
#### Data simulation section
####
# Make a birth-death tree
set.seed(2)
tree <- trees(pars = c(.5, .1), 
              type = "bd", n = 1, 
              max.taxa = 100, 
              include.extinct = FALSE)[[1]]
# Simplify tree & rescale this tree to unit length
tree <- tree[c(1, 3, 5, 2)]
class(tree) <- "phylo"
tree <- geiger::rescale(tree, "depth", 1)
plot(tree)
# Evolve chromosome dataset using 
# old chromevol model 2010
set.seed(2)
data <- simChrom(tree, pars=c(2, 1, 0.1, 0.1, 50), limits=c(2,100), model="2010")
hist(data, breaks=range(data)[2]-range(data)[1]) 

# Evolve chromosome dataset using 
# chromRate model
###
###
###
########################

###
### Loading data
###
data("tree")
data("chrom")
###
###
###

range <- c(min(chrom)-2,max(chrom)+2)

# convert chromosome number to format for diversitree
d.data <- data.frame(names(chrom), chrom)
p.mat <- datatoMatrix(x=d.data, range=range, hyper=F)

# convert chromosome number to format for diversitree with hyperstate
d.data <- data.frame(names(chrom), chrom)
hp.mat <- datatoMatrix(x=d.data, range=range, hyper=T)
# fails as expected when no 3rd state info given 

# lets supply a vector of probabilities
d.data <- data.frame(names(chrom), chrom, runif(100, min=0, max=1))
hp.mat <- datatoMatrix(x=d.data, range=range, hyper=T)

# Now we make the full mkn likelihood function (w/o hyper state)
lik <- make.mkn(tree, states=p.mat, k=ncol(p.mat), strict=F, control=list(method="ode"))

# Constrain to chromevol (w/o hyperstate)
lik.con <- constrainMkn(p.mat, lik)

# check to make sure function is valid
lik.con(rep(.1, 7))

# find MLE
foo <- find.mle(lik.con, x.init = startVals(length(argnames(lik.con)), 0, 1))

# Now we make the full mkn likelihood function (w hyper state)
h.lik <- make.mkn(tree, states=hp.mat, k=ncol(hp.mat), strict=F)

####### This illustrates the outstanding problem of 
####### how we deal with all unknowns in the diversitree framework

# For our purposes we can manually fix one
hp.mat[1, 6] <- 0 

# this will allow us to run make.mkn without error
h.lik <- make.mkn(tree, states=hp.mat, k=ncol(hp.mat), strict=F)

# but we can't get a likelihood
h.lik(startVals(380,0,1))

# we could check that nothing odd is going on by getting rid of all uncertainty
hp.mat[,] <- 0
for(i in 1:nrow(hp.mat)){
  hp.mat[i, sample(1:20, 1)] <- 1
}

# now it works
h.lik <- make.mkn(tree, states=hp.mat, k=ncol(hp.mat), strict=F)
h.lik(startVals(380,0,1))

# add one taxa uncertain
hp.mat[1,] <- 0
hp.mat[1, c(1,11)]<-.5

# mkn now fails
h.lik <- make.mkn(tree, states=hp.mat, k=ncol(hp.mat), strict=F)
h.lik(startVals(380,0,1))
