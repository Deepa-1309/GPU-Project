# Parallel Graph Algorithms on GPU Using GraphBLAS

## Team Members

| Name        | Roll Number |
| ----------- | ----------- |
| Sri Ganga   | 112301043   |
| Sai Deepa   | 112301008   |
| Sindhu Sree | 112301029   |
| Nihitha     | 112301023   |

## Abstract

Large-scale graph processing presents significant computational challenges due to irregular memory access patterns, varying vertex degrees, and dependencies between iterations. Traditional CPU-based graph algorithms can become computationally expensive as the number of vertices and edges increases.

We implement a reusable, templated Sparse Matrix-Vector Multiplication (SpMV) kernel that supports multiple semirings, enabling both Breadth-First Search (BFS) and Connected Components (CC) through a unified computational framework.

---

## Implemented Algorithms

### 1. Breadth-First Search (BFS)

- **Approach:** Performs level-by-level graph traversal using sparse matrix-vector multiplication over the Boolean **(OR, AND) semiring**.
- **CPU Implementation:** Conventional queue-based BFS.
- **CUDA Implementation and Optimizations:**
  - Represents the active vertices at each level using a frontier vector.
  - Performs parallel sparse matrix-vector multiplication between the adjacency matrix and the current frontier.
  - Employs a visited mask to avoid unnecessary processing of previously discovered vertices.
  - Uses kernel to update vertex distances and construct the next frontier.
  - Uses atomic operations to detect frontier exhaustion and terminate traversal.

### 2. Connected Components (CC)

- **Approach:** Identifies connected components through iterative minimum-label propagation using the **(MIN, +) semiring**, with edge weights set to zero.
- **CPU Implementation:** Union-Find (Disjoint Set Union), where the smaller vertex identifier becomes the representative root.
- **CUDA Implementation and Optimizations:**
  - Initializes every vertex with its own identifier as its component label.
  - Performs parallel sparse matrix-vector multiplication to obtain the minimum label among neighboring vertices.
  - Uses kernel to update component labels.
  - Employs atomic operations to detect label changes and determine convergence.
  - Produces component labels consistent with the CPU implementation, enabling direct correctness verification.

---

## Performance Evaluation

### Experimental Environment

- **GPU:** NVIDIA L40
- **Compute Node:** node004
- **Programming Languages:** C++ and CUDA C++
- **Job Scheduling:** SLURM
- **Profiling Tool:** NVIDIA Nsight Systems (`nsys`)

---

## Performance Analysis and Observations

### Small-Scale Graphs

For smaller graphs, CPU implementations outperform GPU implementations because the computational workload is insufficient to compensate for GPU memory allocation, data transfer, and kernel launch overhead.

### Large-Scale Graphs

GPU acceleration becomes beneficial from approximately 16,384 vertices in the tested graphs. As graph size increases, the larger computational workload allows more effective utilization of GPU parallelism.

### BFS Scalability

BFS demonstrates increasing speedup with graph size, achieving a maximum speedup of **8.66×**.

The relatively small diameter of the generated random graphs limits the number of BFS iterations, while increasing graph size provides greater parallel computational work per iteration.

### Connected Components Scalability

Connected Components achieves a maximum speedup of **3.72×**.

Unlike the CPU Union-Find implementation, GPU label propagation repeatedly processes graph edges until convergence. This difference in algorithmic workload limits the achievable speedup despite GPU parallelism.

---

## Project Structure

| File                   | Description                                                               |
| ---------------------- | ------------------------------------------------------------------------- |
| `src/csr.cpp`          | CSR representation, graph construction, and random graph generation       |
| `src/cpu_bfs.cpp`      | Sequential queue-based BFS implementation                                 |
| `src/cpu_cc.cpp`       | Sequential Union-Find implementation                                      |
| `src/gpu_graphblas.cu` | Semiring definitions, generic SpMV kernel, GPU BFS and CC implementations |
| `src/main.cu`          | Benchmarking, execution, correctness verification, and result reporting   |
| `testcases.sh`         | SLURM script for compilation and benchmark execution                      |
| `profiling.sh`         | SLURM script for NVIDIA Nsight Systems profiling                          |

The `main.cu` file includes the required implementation files, allowing the project to be compiled as a single translation unit.

##
