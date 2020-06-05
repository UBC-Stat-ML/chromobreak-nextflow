Requirements
------------

Java 8+ JDK, UNIX, R with tidyverse and git.


Usage
-----

### Data preparation

- Directory organization: for each condition, create a sub-directory in the folder ``data``. See for example ``data/X0569_422234x`` provided as an example. This sub-directory should contain two files: ``initial.csv`` for initial counts; and ``final.csv`` for the final counts. The final counts can contain several experimental replicates. 


- File for the initial counts, e.g. ``data/X0569_422234x/initial.csv``, should have the following format:

```
sgRNA,gene,counts
1,ctl,1644
2,ctl,7900
...
```

- File for the final counts, e.g. ``data/X0569_422234x/final.csv``, should have the following format:

```
dataset,barcode,sgRNA,M,gene
X0569_4222341_clones,1,1,131,ctl_22
X0569_4222341_clones,2,1,109,ctl_22
...
```

- Controls should have the prefix ``ctl`` in their gene identifier


### Running the GoF (Goodness of Fit) diagnostics

```
./nextflow run GoF.nf -resume 
```

This will create the following output in the directory ``deliverables/GoF``

- ``gof.pdf`` actual coverage of 90% credible intervals for a few observed quantities, shown across all datsets (x axis) and different methods (colours). Each actual coverage is averaged over the targets. 
- ``width.pdf``: average interval widths
- ``gof-data.csv``: statistics used for above plots
- ``runs/[data]_[model]/``: contains details from the run, including
    - ``ess`` effective sample sizes
    - ``estimates.csv``: credible intervals
    - ``plots/intervals.pdf``: credible intervals plots
    - ``posteriorPlots``: marginal posterior density estimates
    - ``tracePlots``: trace plots post burn-in
    - ``tracePlotsFull``: including burn-in

Some configurations available:

```
./nextflow run GoF.nf -resume [options]
```

- ``--model "BNB MixBNB MixNBLocalLambdaMixBNB MixYS NB Poi YS"``: space-separated list of models to run (note required quotes)
- ``--nScans 1000``: control number of MCMC scans (default 1000)
- ``--nInitParticles 10``: increase this if model initialization fails (can happen in complex mixture models with vague priors, default 10)
- ``nTargets INF``: use this to do inference on a subset of targets (e.g. for dry runs)
- In ``GoF.nf`` uncomment the following to send to SGE cluster (run from head node i.e. with access to qsub):

```
  // cpus 1
  // executor 'sge'
  // memory '1 GB'
  // time '10h
```


### Running the Holdout diagnostics

```
./nextflow run holdout.nf -resume --dataset X0569_422234x --maxNExperiments 4 --lastDataset X0569_4222344_clones
```

where:

- ``dataset`` should give the name of one of the subdirectories in ``./data``
- ``maxNExperiments`` should contain the number of replicates in that dataset
- ``lastDataset``, the reference replicate, typically the last replicate code to appear in the final csv file

Outputs and configurations are similar to the GoF code, the main exception being the following files in the ``deliverables/holdout`` directory:

- ``generalization-coverage.pdf``: actual coverage for the reference dataset as more replicates are used
- ``generalization-width.pdf``: width as a function of number of replicates used
- ``gd-data.csv``: statistics used for above plots


### Running the analysis pipeline


```
./nextflow run poset-pipeline.nf -resume
```

Again, outputs and configurations are similar to the GoF code, the main exception being the following files in the ``deliverables/poset-pipeline`` directory:

- ``posets/[dataset]_[model].dot``: poset in dot format
- ``posets/[condition1]_[condition2]_[conditioni].dot`` poset comparisons between condition 1 and condition 2, showing for condition i an assignment of edge changes into vertices that are likely to have changed position

Also, by default all replicates are used, this can be controlled with the switch ``--nExperiments``, for example ``--nExperiments 1`` to use at most 1 replicates.
