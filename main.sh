#!/bin/bash

./nextflow run main.nf -resume "$@" | nf-monitor --open false