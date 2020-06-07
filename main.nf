#!/usr/bin/env nextflow

pwd=new File(".").getAbsolutePath()

params.reads
params.gc
params.dryRun = false

dryRunLimit = Integer.MAX_VALUE
if (params.dryRun) {
  dryRunLimit = 2
}

reads = file(params.reads)
gc = file(params.gc)

if (reads == null || gc == null) {
  throw new RuntimeException("Required options: --reads and --gc")
}

deliverableDir = 'deliverables/' + workflow.scriptName.replace('.nf','') + "_" + params.reads + "/"


process buildCode {
  cache true 
  input:
    val gitRepoName from 'nowellpack'
    val gitUser from 'UBC-Stat-ML'
    val codeRevision from 'f6d29b758a83ee6e09d0f0b282a5cfc4a5a5293d'
    val snapshotPath from "${System.getProperty('user.home')}/w/nowellpack"
  output:
    file 'code' into code
  script:
    template 'buildRepo.sh' 
}


process preprocess {
  input:
    file code
    file reads
    file gc
  output:
    file 'results/preprocessed' into preprocessed
    file 'results/preprocessed/tidyReads/tidy/*/data.csv.gz' into cells
  """
  java -cp code/lib/\\* -Xmx1g chromobreak.Preprocess \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --reads $reads \
    --gc $gc \
    --maxNCells $dryRunLimit 
  mv results/latest results/preprocessed
  """
}


process run { 
  echo true
  input:
    each cell from cells
    file code
    file preprocessed
  output:
    file 'results/latest' into runs
  """
  java -cp code/lib/\\* -Xmx1g chromobreak.SingleCell \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --model.data.source $preprocessed/tidyGC/tidy.csv.gz \
    --model.data.gcContents.name value \
    --model.data.readCounts.name value \
    --model.data.readCounts.dataSource $preprocessed/tidyReads/tidy/${cell.parent.name}/data.csv.gz \
    --engine.nScans ${Math.min(200, dryRunLimit)} \
    --engine PT \
    --engine.nChains 1 \
    --engine.initialization FORWARD \
    --model.configs.annealingStrategy Exponentiation \
    --model.configs.annealingStrategy.thinning 1  \
    --engine.nPassesPerScan 1 \
    --postProcessor chromobreak.ChromoPostProcessor \
    --postProcessor.runPxviz false \
    --engine.nThreads Single
  echo "\ncell\t${cell.parent.name}" >> results/latest/arguments.tsv
  """
}

process aggregate {
  input:
    file 'exec_*' from runs.toList()
    file code
    file preprocessed
  """
  java -cp code/lib/\\* -Xmx1g corrupt.pre.ComputeDeltas \
    --experimentConfigs.resultsHTMLPage false \
    --source FromPosteriorSamples \
    --source.files `find . | grep exec` \
    --source.lociIndexFile $preprocessed/tidyReads/lociIndex.csv.gz
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
