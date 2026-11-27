#!/bin/bash
#SBATCH --job-name=graphblas_profile
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/profiling_%j.out
#SBATCH --error=logs/profiling_%j.err

set -euo pipefail

PROJECT_DIR="${SLURM_SUBMIT_DIR}"
SIF="/home/singularity_sif/pytorch23.02.sif"
NSYS="/opt/ohpc/pub/apps/cuda/12.1/bin/nsys"
PROFILE_BASE="profiles/graphblas_${SLURM_JOB_ID}"

echo "CUDA GraphBLAS Nsight Systems profiling"
echo "Job ID : ${SLURM_JOB_ID}"
echo "Node   : $(hostname)"
echo "Folder : ${PROJECT_DIR}"
echo "Started: $(date)"

if [[ ! -f "${SIF}" ]]; then
    echo "ERROR: Singularity image not found: ${SIF}" >&2
    exit 1
fi

if [[ ! -x "${NSYS}" ]]; then
    echo "ERROR: Nsight Systems not found or not executable: ${NSYS}" >&2
    exit 1
fi

mkdir -p "${PROJECT_DIR}/profiles"

singularity exec --nv \
    --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
    --pwd "${PROJECT_DIR}" \
    "${SIF}" \
    bash -lc 'set -euo pipefail; make clean; make'

echo "Starting Nsight Systems capture..."

singularity exec --nv \
    --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
    --pwd "${PROJECT_DIR}" \
    "${SIF}" \
    "${NSYS}" profile \
        --trace=cuda \
        --force-overwrite=true \
        -o "${PROJECT_DIR}/${PROFILE_BASE}" \
        "${PROJECT_DIR}/gb"

PROFILE_FILE="${PROJECT_DIR}/${PROFILE_BASE}.nsys-rep"

if [[ -f "${PROFILE_FILE}" ]]; then
    echo "Profiling report: ${PROFILE_FILE}"
    echo "Generating Nsight Systems summary..."
    singularity exec --nv \
        --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
        --pwd "${PROJECT_DIR}" \
        "${SIF}" \
        "${NSYS}" stats \
            --report cuda_api_sum,cuda_gpu_kern_sum,cuda_gpu_mem_time_sum,cuda_gpu_mem_size_sum \
            "${PROFILE_FILE}"
else
    echo "ERROR: Expected profiling report was not created: ${PROFILE_FILE}" >&2
    exit 1
fi

echo "Finished: $(date)"
echo "Profile: ${PROFILE_FILE}"
echo "Exit status: 0"


