#!/usr/bin/env nextflow

pwd=new File(".").getAbsolutePath()

params.deltas
params.cns
params.dryRun = false

params.dryRunLimit = 4
dryRunLimit = Integer.MAX_VALUE
if (params.dryRun) {
  dryRunLimit = params.dryRunLimit
}

deltasDir = file(params.deltas)
cnsDir = file(params.cns)

if (!deltasDir.exists() || !cnsDir.exists()) {
  throw new RuntimeException("Required options should point to directories: --deltas and --cns")
}

deltas = Channel.fromPath( deltasDir + '/matrix-*' )
cns = Channel.fromPath( cnsDir + '/*.csv*' )

process buildCode {
  cache true 
  input:
    val gitRepoName from 'nowellpack'
    val gitUser from 'UBC-Stat-ML'
    val codeRevision from '48b171fd01e906a740eac97a7f0ad821a9b67505'
    val snapshotPath from "${System.getProperty('user.home')}/w/nowellpack"
  output:
    file 'code' into code
  script:
    template 'buildRepo.sh' 
}



process dejitter {
  input:
    each delta from deltas
    file code
  output:
    file 'results/dejittered' into dejittered
  """
  java -cp code/lib/\\* -Xmx8g corrupt.pre.StraightenJitter \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --maxError 0.1 \
    --input ${delta}
  mv results/latest results/dejittered
  """
}

dejittered.into {
  dejittered_filter
  dejittered_viz
}

process filterLoci {
  input:
    file 'dejittered/exec_*' from dejittered_filter.toList()
    file code
  output:
    file 'results/filtered' into filtered
  """
  java -cp code/lib/\\* -Xmx8g corrupt.pre.Filter \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --inputs `find -L  dejittered -name "exec_*" -print`
  mv results/latest results/filtered
  """
}


process inferTree {
  input:
    file filtered
    file code
  output:
    file 'results/sitka' into sitka
  """
  java -cp code/lib/\\* -Xmx8g corrupt.NoisyBinaryModel \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --model.binaryMatrix $filtered/filtered-shrunk.csv.gz \
    --model.globalParameterization true \
    --model.fprBound 0.1 \
    --model.fnrBound 0.5 \
    --model.minBound 0.001 \
    --engine PT \
    --engine.nChains 1 \
    --engine.nScans ${Math.min(200, dryRunLimit)} \
    --engine.thinning 1 \
    --postProcessor corrupt.post.CorruptPostProcessor \
    --model.samplerOptions.useCellReallocationMove true \
    --postProcessor.runPxviz true \
    --engine.nPassesPerScan 0.5 \
    --model.predictivesProportion 0.00 \
    --engine.nThreads MAX \
    --engine.scmInit.nParticles 1000 \
    --engine.initialization FORWARD \
    --stripped false \
    --engine.random 1 \
    --model.samplerOptions.useMiniMoves false
  mv results/latest results/sitka
  """
}


process treeOrderedViz {
  input:
    file sitka
    file 'dejittered/exec_*' from dejittered_viz.toList()
    file filtered
    file code
  """
  java -cp code/lib/\\* -Xmx8g corrupt.viz.SplitPerfectPhyloViz \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --phylo file ${sitka}/consensus.newick \
    --matrices `ls $deltasDir/*gz` \
    --suffix step_1_delta \
    --size width 300
  mv results/latest/output/*.pdf .
  
  java -cp code/lib/\\* -Xmx8g corrupt.viz.SplitPerfectPhyloViz \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --phylo file ${sitka}/consensus.newick \
    --matrices `find -L  dejittered -name "binarized.csv.gz" -print` \
    --suffix step_2_dejittered \
    --size width 300
  mv results/latest/output/*.pdf .
  
  java -cp code/lib/\\* -Xmx8g corrupt.viz.SplitPerfectPhyloViz \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --phylo file ${sitka}/consensus.newick \
    --matrices filtered/filtered-full.csv.gz \
    --suffix step_3_filtered \
    --size width 300
  mv results/latest/output/*.pdf .
  """
}

process cnaViz {
  input:
    file code
    each snapshot from cns
    file sitka
  """
  java -cp code/lib/\\* -Xmx8g corrupt.viz.SplitPerfectPhyloViz \
    --experimentConfigs.resultsHTMLPage false \
    --experimentConfigs.tabularWriter.compressed true \
    --phylo file ${sitka}/consensus.newick \
    --matrices $snapshot \
    --colourCodes 0 12 \
    --size width 300
  """
}

