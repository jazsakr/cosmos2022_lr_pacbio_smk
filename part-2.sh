#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh
conda activate snakemake

python -m snakemake -s ./snakemake/part-2.smk -j 4 --use-conda --configfile config.yaml \
--cluster 'sbatch -A cosmos2022 --mem {resources.mem_gb}G --cpus-per-task {threads} --output=$PWD/slurm_logs/slurm-%j.out' \
--latency-wait 60
