#!/usr/bin/env nextflow

pwd=new File(".").getAbsolutePath()

params.reads
params.gc
params.dryRun = false

params.dryRunLimit = 4
dryRunLimit = Integer.MAX_VALUE
if (params.dryRun) {
  dryRunLimit = params.dryRunLimit
}

reads = file(params.reads)
gc = file(params.gc)

if (reads == null || gc == null) {
  throw new RuntimeException("Required options: --reads and --gc")
}

dryRunSuffix = ""
if (params.dryRun) {
  dryRunSuffix = "-dryRun"
}
deliverableDir = 'deliverables/cn-calls/' + reads.name.replace('.csv','').replace('.gz','') + dryRunSuffix

process buildCode {
  cache true 
  input:
    val gitRepoName from 'nowellpack'
    val gitUser from 'UBC-Stat-ML'
    val codeRevision from '49e5f92896a2fcd88bb0d5d2970ed90c9079a5fa'
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
  java -cp code/lib/\\* -Xmx2g chromobreak.Preprocess \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --reads $reads \
    --gc $gc \
    --maxNCells $dryRunLimit \
    --maxNChromosomes $dryRunLimit 
  mv results/latest results/preprocessed
  """
}


process inferCopyNumbers { 
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
    --model.configs.maxStates 10 \
    --engine.nPassesPerScan 1 \
    --postProcessor chromobreak.ChromoPostProcessor \
    --postProcessor.runPxviz true \
    --engine.nThreads Single
  echo "\ncell\t${cell.parent.name}" >> results/latest/arguments.tsv
  """
}

process computeDeltas {
  input:
    file 'runs/exec_*' from runs.toList()
    file code
    file preprocessed
  output:
    file 'results/deltas/matrix-*.csv.gz' into deltas
    file 'results/deltas/snapshot/*.csv.gz' into snapshots
  publishDir deliverableDir, mode: 'copy', overwrite: true
  """
  java -cp code/lib/\\* -Xmx8g corrupt.pre.ComputeDeltas \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --source FromPosteriorSamples \
    --source.files `find runs | grep exec` \
    --source.lociIndexFile $preprocessed/tidyReads/lociIndex.csv.gz
  mv results/latest results/deltas
  mv results/deltas/matrix-2.csv.gz results/deltas/bu #ignore small jumps - noisy
  """
}

