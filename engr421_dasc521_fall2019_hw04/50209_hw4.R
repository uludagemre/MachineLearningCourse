#read data 
#setwd('/home/emre/Documents/CollegeFiles/COMP421/MachineLearningCourse/engr421_dasc521_fall2019_hw04')
data <- read.csv('hw04_data_set.csv')

#split data into trest and training data
training_data <- data[1:150,]
test_data <- data[151:272,]


#parameters for regressogram
bin_width <- 0.37
origin <- 1.5
x_maximum <- max(data$eruptions)

regressogram <- function(data, bin_width, origin, x_max){
  bin_number <- ceiling((data$eruptions - origin) / bin_width)
  regressogram_data <- cbind(data, bin_number)
  bin_means <- aggregate(x = regressogram_data$waiting,
                         by = list(regressogram_data$bin_number),
                         FUN = mean)
  colnames(bin_means) <- c('bin_number', 'bin_mean')
  n <- (x_max - origin) / bin_width
  for(i in 1:n){
    if(!any(bin_means$bin_number == i)){
      bin_means <- rbind(bin_means, c(i, 0.0))
    }
  }
  return (bin_means[with(bin_means, order(bin_number)), ])
}

training_regressogram<-regressogram(training_data, bin_width,origin,x_maximum)

plot(x = training_data$eruptions,
     y = training_data$waiting,xlab = 'Waiting time to next eruption (min)',ylab = 'Eruption time (min)',type = 'p',pch = 20,col = 'blue',xlim = c(origin, x_maximum))
points(x = test_data$eruptions,y = test_data$waiting,type = 'p',pch = 20,col = 'red')

dummy_x <- (1:nrow(training_regressogram) / (1/bin_width)) + origin
draw_data <- data.frame(cbind(dummy_x,training_regressogram$bin_mean))

#the dummy is put here in order to initiate the line from the origin
dummy <- data.frame(origin,training_regressogram$bin_mean[1])
colnames(dummy) <- c('x','bin_mean')
colnames(draw_data) <- c('x', 'bin_mean')

#add the first element of bin_means to draw data 
draw_data <- rbind(dummy,draw_data)
lines(x = draw_data$x,
      y = draw_data$bin_mean,
      xlab = 'Waiting time to next eruption (min)',
      ylab = 'Eruption time (min)',
      type = 'S')
title(main = 'h = 0.37')

legend(x = min(data$eruptions)-0.2, y= max(data$waiting)-25 , legend = c('training', 'test'),col = c('blue', 'red'), pch = 20, xjust = 0, yjust = 0,cex=0.75)

############################################################
#w function for running mean smoother
w <- function(x){
  x <- data.frame(abs(x))
  x <- apply(X = x, MARGIN = c(1, 2),FUN = function(e){
               if (e <= 0.5){
                 e <- 1
               }else{
                 e <- 0
               }
             })
  return (x)
}

#running mean smoother function with data_interval, data and bin_width parameters
rms <- function(data_interval, data, bin_width){
  g_head <- sapply(X = data_interval, FUN = function(x){sum(w((x - data$eruptions) / bin_width) * data$waiting) /sum(w((x - data$eruptions) / bin_width))})
  result <- data.frame(data_interval)
  result <- cbind(result, g_head)
  colnames(result) <- c('x', 'rms')
  return (result)
}
#Calculation of RMSE 
bin_number <- ceiling((test_data$eruptions - origin) / bin_width)
test_regressogram <- cbind(test_data, bin_number)
test_regressogram <- merge(x = test_regressogram,y = training_regressogram,by = 'bin_number')
test_regressogram_rmse <- sqrt(sum((test_regressogram$waiting - test_regressogram$bin_mean)**2) / nrow(test_regressogram))
cat('Regressogram => RMSE is', test_regressogram_rmse,'when h is', bin_width, '\n')

#mean smoother parameters
rms_bin_width <- 0.37
rms_origin <- 1.5
rms_x_max <- max(data$eruptions)
rms_data_interval <- seq(from = rms_origin, to = rms_x_max, by = 0.02)

#running mean smoother of train_data with bin width: 0.37
train_data_rms <- rms(data_interval = rms_data_interval,
                      data = training_data,
                      bin_width = rms_bin_width)

#plotting train_data, test_data and running mean smoother of train_data
plot(x = training_data$eruptions,y = training_data$waiting,xlab = 'eruptions',ylab = 'waiting',type = 'p',pch = 20,col = 'blue',xlim = c(rms_origin, rms_x_max))
points(x = test_data$eruptions,y = test_data$waiting,type = 'p',pch = 20,col = 'red')
lines(x = train_data_rms$x,y = train_data_rms$rms,xlab = 'eruptions',ylab = 'waiting',type = 'l')
title(main = 'h = 0.37')
legend(x = min(data$eruptions)-0.2, y= max(data$waiting)-25, legend = c('training', 'test'),col = c('blue', 'red'), pch = 20, xjust = 0, yjust = 0)

#calculating RMSE of running mean smoother for test_data

test_data_rms <- train_data_rms[ceiling(test_data$eruptions * ((length(rms_data_interval) - 1) / (rms_x_max - rms_origin+2)) + 1), ]
test_data_rms_rmse <- sqrt(sum((test_data$waiting - test_data_rms$rms)**2) /nrow(test_data_rms))
cat('Running Mean Smoother => RMSE is', test_data_rms_rmse,'when h is', rms_bin_width)

#Kernel smoothing part
#k function for kernel smoother
k <- function(x){return ((1 / sqrt(2 * pi)) * exp(-(x ** 2) / 2))}
#kernel smoother function with data_interval, data and bin_width parameters
ks <- function(data_interval, data, bin_width){
  g_head <- sapply(X = data_interval, FUN = function(x){sum(k((x - data$eruptions) / bin_width) * data$waiting) /sum(k((x - data$eruptions) / bin_width))})
  result <- data.frame(data_interval)
  result <- cbind(result, g_head)
  colnames(result) <- c('x', 'ks')
  return (result)
}
#kernel smoother parameters
ks_bin_width <- 0.37
ks_origin <- 1.5
ks_x_max <- max(data$eruptions)
ks_data_interval <- seq(from = ks_origin, to = ks_x_max, by = 0.1)

#kernel smoother of train_data with bin width: 1
train_data_ks <- ks(data_interval = ks_data_interval,data = training_data,bin_width = ks_bin_width)

#plotting train_data, test_data and kernel smoother of train_data
plot(x = training_data$eruptions,y = training_data$waiting,xlab = 'erruptions',ylab = 'waiting',type = 'p',pch = 20,col = 'blue',xlim = c(ks_origin, ks_x_max))
points(x = test_data$eruptions,y = test_data$waiting,type = 'p',pch = 20,col = 'red')
lines(x = train_data_ks$x,y = train_data_ks$ks,xlab = 'x',ylab = 'y',type = 'l')
title(main = 'h = 0.37')
legend(x = min(data$eruptions)-0.2, y= max(data$waiting)-25, legend = c('training', 'test'),col = c('blue', 'red'), pch = 20, xjust = 0, yjust = 0)

#calculating RMSE of kernel smoother for test_data
test_data_ks <- train_data_ks[ceiling(test_data$eruptions * ((length(ks_data_interval) - 1) / (ks_x_max - ks_origin+2))), ]
test_data_ks_rmse <- sqrt(sum((test_data$waiting - test_data_ks$ks)**2) /nrow(test_data_ks))
cat('Kernel Smoother => RMSE is', test_data_ks_rmse,'when h is', ks_bin_width)
