#####################
#Title: SQL Tutorial
#Author: Tony Chang
#Date: 06/10/2015
#Abstract:  short tutorial on using the sqldf library in R version 3.2.0 
#           and digging into the FIA dataset
#           look at the methods to understand the many .csv files and the codes/meaning
#           http://www.fia.fs.fed.us/library/field-guides-methods-proc/
#          
#           All the CSV datafile can be downloaded at http://apps.fs.fed.us/fiadb-downloads/datamart.html 
#           at the bottom of the webpage. The ones necessary for this tutorial are TREE.CSV and PLOT.CSV

#           The REF_SPECIES.CSV can be found provided by TCHANG or found on page 226-235 of the Appendix F from the FIA Manual
#           http://www2.latech.edu/~strimbu/Teaching/FOR425/Species_Code_FIA.pdf
#####################

#######LOADING LIBRARIES##############
#install.packages("data.table") #uncomment these to install packages
#install.packages("sqldf")
#note that the 'sqldf' library requires the R version 3.2.0

require(sqldf) #this is the sql library for R
require(data.table) #need this library to load the csv much faster as the datafiles are >1.0 GB

#######LOADING DATA##############
plotfile = "E:\\FIA\\PLOT.csv"
plot_cols = colnames(read.csv(file = plotfile, nrows = 1)) #get the column names within plots to look up
plot_scols = c("CN", "PLOT", "LAT", "LON", "ELEV") #and create a list of the column you want to reduce csv load time
plots = fread(plotfile, sep = ",", select = plot_scols, showProgress=T)

treefile = "E:\\FIA\\TREE.CSV"
tree_cols = colnames(read.csv(file = treefile, nrows = 1)) #get the column names within trees
tree_scols = c('CN', 'PLT_CN', 'PLOT', 'SPCD', 'TREE', 'DIA', 'HT') #and create a list of the column you want to reduce csv load time
trees = fread(treefile, sep = ",", select = tree_scols, showProgress=T)

#get the species code for each tree
spcdfile = "E:\\FIA\\REF_SPECIES.CSV"
spcds = fread(spcdfile, sep = ',')

###########QUERYING##############
#now query to find where species is the latin name
wbp_code = sqldf("SELECT SPCD FROM spcds WHERE SPECIES = 'albicaulis'") #this queries for the species albicaulis

#now query where tree is equal to this species code
wbp = sqldf(sprintf("SELECT * FROM trees WHERE SPCD = %s",wbp_code))

#additionally we can query by the other attributes such as DIA or HT or anything else...
#in general the syntax is "SELECT attribute_field FROM dataset WHERE logical_statements)
#note: I use the 'sprintf' function in the base library of R to refer to variables rather 
#than having to explicitly type the value for my logical conditions see http://www.cookbook-r.com/Strings/Creating_strings_from_variables/ 

#############JOINING#############
#we can try to group by the PLT_CN and get a count of the number of wbp within that PLOT
wbp_counts = sqldf("SELECT PLT_CN, COUNT (PLT_CN) as wbp_occurances FROM wbp GROUP BY PLT_CN")

#from here we can join this with the 'plots' variable that has the topographic information 
#now join to the plots that match
wbp_plots = sqldf("SELECT * FROM wbp_counts, plots WHERE wbp_counts.PLT_CN=plots.CN ")
#we have combined the wbp_counts and plots tables by PLT_CN

plot(wbp_plots$LON, wbp_plots$LAT) #we can see we have much more than the GYE currently

#suppose now we would like to subset this by the LAT and LON within the GYE
xmax = -108.263
xmin = -112.436
ymin = 42.252
ymax = 46.182
#specify the bounds for the FIA data
#with these bounds we can subset to the LAT and LON of our specifications
wbp_GYE = sqldf(sprintf("SELECT * FROM wbp_plots WHERE LAT>=%s AND LAT<=%s AND LON>=%s AND LON<=%s",ymin, ymax, xmin, xmax))
plot(wbp_GYE$LON, wbp_GYE$LAT) #now all we have are wbp within the GYE

############WRITING###############
#finally perhaps we would like to write this table to a new csv file
filename = 'E:\\RSQL_test\\wbp_GYE.csv'
write.table(wbp_GYE, file =sprintf('%s', filename), sep = ',')
#these methods can be repeated for different bounding box areas and different species