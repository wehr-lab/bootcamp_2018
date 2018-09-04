library(R.matlab)
library(reshape2)
library(plyr)
library(ggplot2)

out <- read.csv('/Users/jonny/GitHub/bootcamp_2018/out_134_spikes.csv')

# raster
ggplot(out, aes(x=spikes,y=rep))+
  geom_point(size=0.5)+
  facet_grid(icis~.)

# n_spikes per rep
spikes.rep <- ddply(out[out$spikes>0 & out$spikes<2000,],.(icis,rep),summarize,
                    n_spikes = length(spikes))
ggplot(spikes.rep,aes(x=as.factor(icis),y=n_spikes))+
  geom_point()

spikes.stim <- ddply(spikes.rep,.(icis),summarize,
                     mean_spikes =mean(n_spikes),
                     sd_spikes = sd(n_spikes))
ggplot(spikes.stim,aes(x=as.factor(icis),y=mean_spikes))+
  geom_pointrange(aes(ymin=mean_spikes-sd_spikes, ymax=mean_spikes+sd_spikes))

