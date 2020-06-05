#!/usr/bin/env nextflow

pwd=new File(".").getAbsolutePath()

params.dataset
params.nCells = 200

cells = 0..(params.nCells-1)

deliverableDir = 'deliverables/' + workflow.scriptName.replace('.nf','') + "_" + params.dataset + "/"


process buildCode {
  cache true 
  input:
    val gitRepoName from 'nowellpack'
    val gitUser from 'UBC-Stat-ML'
    val codeRevision from 'c2b4930fbd4a77f6d609e812129bf950fc5a6f49'
    val snapshotPath from "${System.getProperty('user.home')}/w/nowellpack"
  output:
    file 'code' into code
  script:
    template 'buildRepo.sh' 
}

process run {

  input:
    each cell from cells
    file code
  output:
    file 'results/latest' into runs
  """
  java -cp code/lib/\\* -Xmx1g chromobreak.SingleCell \
    --model.data.source ${pwd}/data/${params.dataset}_uncor_gc_simplified.csv \
    --model.data.gcContents.name value \
    --model.data.readCounts.name value \
    --model.data.readCounts.dataSource ${pwd}/data/${params.dataset}_uncor_reads_split/${cell}.csv \
    --engine.nScans 200 \
    --engine PT \
    --engine.nChains 20 \
    --engine.initialization FORWARD \
    --model.configs.annealingStrategy Exponentiation \
    --model.configs.annealingStrategy.thinning 1  \
    --engine.nPassesPerScan 1 \
    --postProcessor chromobreak.ChromoPostProcessor \
    --postProcessor.runPxviz true \
    --excludeFromOutput \
    --engine.nThreads Single
  echo "\ncell\t$cell" >> results/latest/arguments.tsv
  """
}

process analysisCode {
  input:
    val gitRepoName from 'nedry'
    val gitUser from 'alexandrebouchard'
    val codeRevision from 'cf1a17574f19f22c4caf6878669df921df27c868'
    val snapshotPath from "${System.getProperty('user.home')}/w/nedry"
  output:
    file 'code' into analysisCode
  script:
    template 'buildRepo.sh'
}


process aggregatePaths {
  input:
    file analysisCode
    file 'exec_*' from runs.toList()
  output:
    file 'hmms' into aggregatedPaths
    file 'f0s' into f0s
    file 'f1s' into f1s
    file 'f2s' into f2s
    file 'logDensity' into logDensity
  """
  code/bin/aggregate \
    --dataPathInEachExecFolder hmms.csv \
    --keys cell from arguments.tsv
  mv results/latest/aggregated hmms
  code/bin/aggregate \
    --dataPathInEachExecFolder samples/f0.csv \
    --keys cell from arguments.tsv
  mv results/latest/aggregated f0s
  code/bin/aggregate \
    --dataPathInEachExecFolder samples/f1.csv \
    --keys cell from arguments.tsv
  mv results/latest/aggregated f1s
  code/bin/aggregate \
    --dataPathInEachExecFolder samples/f2.csv \
    --keys cell from arguments.tsv
  mv results/latest/aggregated f2s
  code/bin/aggregate \
    --dataPathInEachExecFolder samples/logDensity.csv \
    --keys cell from arguments.tsv
  mv results/latest/aggregated logDensity
  """
}


process plotF0s {
  input:
    file f0s
    env SPARK_HOME from "${System.getProperty('user.home')}/bin/spark-2.1.0-bin-hadoop2.7"

  afterScript 'rm -r metastore_db; rm derby.log'
  """
  #!/usr/bin/env Rscript
  require("ggplot2")
  require("stringr")
  library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
  sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "8g"))

  data <- read.df("$f0s", "csv", header="true", inferSchema="true")
  data <- collect(data)
  
  require("dplyr")
  data <- data %>% filter(sample > 100)
  p <- ggplot(data, aes(x = value, colour = factor(cell))) +
                geom_density() + 
                theme_bw() +
                facet_grid(cell ~ .) + 
                theme(legend.position = "none") +
                ylab("density") +
                xlab("F0") 
  ggsave(filename = "densityF0.pdf", plot = p, width = 3, height = 50, limitsize = FALSE) 
  """
}


process plotF1s {
  input:
    file f1s
    env SPARK_HOME from "${System.getProperty('user.home')}/bin/spark-2.1.0-bin-hadoop2.7"

  afterScript 'rm -r metastore_db; rm derby.log'
  """
  #!/usr/bin/env Rscript
  require("ggplot2")
  require("stringr")
  library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
  sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "8g"))

  data <- read.df("$f1s", "csv", header="true", inferSchema="true")
  data <- collect(data)
  
  require("dplyr")
  data <- data %>% filter(sample > 100)
  p <- ggplot(data, aes(x = value, colour = factor(cell))) +
                geom_density() + 
                theme_bw() +
                facet_grid(cell ~ .) + 
                theme(legend.position = "none") +
                ylab("density") +
                xlab("F1") 
  ggsave(filename = "densityF1.pdf", plot = p, width = 3, height = 50, limitsize = FALSE) 
  """
}


process plotF2s {
  input:
    file f2s
    env SPARK_HOME from "${System.getProperty('user.home')}/bin/spark-2.1.0-bin-hadoop2.7"

  afterScript 'rm -r metastore_db; rm derby.log'
  """
  #!/usr/bin/env Rscript
  require("ggplot2")
  require("stringr")
  library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
  sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "8g"))

  data <- read.df("$f2s", "csv", header="true", inferSchema="true")
  data <- collect(data)
  
  require("dplyr")
  data <- data %>% filter(sample > 100)
  p <- ggplot(data, aes(x = value, colour = factor(cell))) +
                geom_density() + 
                theme_bw() +
                facet_grid(cell ~ .) + 
                theme(legend.position = "none") +
                ylab("density") +
                xlab("F2") 
  ggsave(filename = "densityF2.pdf", plot = p, width = 3, height = 50, limitsize = FALSE) 
  """
}

process plotLogD {
  input:
    file logDensity
    env SPARK_HOME from "${System.getProperty('user.home')}/bin/spark-2.1.0-bin-hadoop2.7"

  afterScript 'rm -r metastore_db; rm derby.log'
  """
  #!/usr/bin/env Rscript
  require("ggplot2")
  require("stringr")
  library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
  sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "8g"))

  data <- read.df("$logDensity", "csv", header="true", inferSchema="true")
  data <- collect(data)
  
  require("dplyr")
  data <- data %>% filter(sample > 100)
  p <- ggplot(data, aes(x = value, colour = factor(cell))) +
                geom_density() + 
                theme_bw() +
                facet_grid(cell ~ .) + 
                theme(legend.position = "none") +
                ylab("density") +
                xlab("logDensity") 
  ggsave(filename = "logDensity.pdf", plot = p, width = 3, height = 50, limitsize = FALSE) 
  """
}




process summarizePipeline {
  cache false 
  output:
      file 'pipeline-info.txt'
  publishDir deliverableDir, mode: 'copy', overwrite: true
  """
  echo 'scriptName: $workflow.scriptName' >> pipeline-info.txt
  echo 'start: $workflow.start' >> pipeline-info.txt
  echo 'runName: $workflow.runName' >> pipeline-info.txt
  echo 'nextflow.version: $workflow.nextflow.version' >> pipeline-info.txt
  """
}
