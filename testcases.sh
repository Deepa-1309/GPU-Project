#!/bin/bash
#SBATCH --job-name=graphblas_test
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/testcases_%j.out
#SBATCH --error=logs/testcases_%j.err

set -euo pipefail

PROJECT_DIR="${SLURM_SUBMIT_DIR}"
SIF="/home/singularity_sif/pytorch23.02.sif"

echo "CUDA GraphBLAS correctness/performance run"
echo "Job ID : ${SLURM_JOB_ID}"
echo "Node   : $(hostname)"
echo "Folder : ${PROJECT_DIR}"
echo "Started: $(date)"

if [[ ! -f "${SIF}" ]]; then
    echo "ERROR: Singularity image not found: ${SIF}" >&2
    exit 1
fi

singularity exec --nv \
    --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
    --pwd "${PROJECT_DIR}" \
    "${SIF}" \
    bash -lc 'set -euo pipefail; make clean; make; make test'

status=$?

echo "Finished: $(date)"
echo "Exit status: ${status}"
exit "${status}"

