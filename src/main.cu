
#include <iostream>
#include <vector>
#include <chrono>
#include <algorithm>
#include <cstdio>
#include <cstdlib>

#include "csr.cpp"
#include "cpu_bfs.cpp"
#include "cpu_cc.cpp"
#include "gpu_graphblas.cu"

using namespace std;

double now() {
    return chrono::duration<double, milli>(
        chrono::steady_clock::now().time_since_epoch()).count();
}

double medianTime(vector<double> times) {
    sort(times.begin(), times.end());
    return times[times.size() / 2];
}

template <class Function>
double measureTime(Function fn, int repeats) {
    vector<double> times;

    for (int i = 0; i < repeats; i++) {
        double start = now();
        fn();
        times.push_back(now() - start);
    }

    return medianTime(times);
}

void evaluateGraph(const char *structure, Graph &g, int src, int repeats) {
    bfsGPU(g, src);
    ccGPU(g);

    vector<int> cpuDist, gpuDist, cpuLab, gpuLab;

    auto cpuBFSFunction = [&]() {  cpuDist = bfsCPU(g, src);};

    auto gpuBFSFunction = [&]() {gpuDist = bfsGPU(g, src);cudaDeviceSynchronize();};

    auto cpuCCFunction = [&]() {cpuLab = ccCPU(g);};

    auto gpuCCFunction = [&]() {gpuLab = ccGPU(g); cudaDeviceSynchronize();};

    double cpuBFS = measureTime(cpuBFSFunction, repeats);
    double gpuBFS = measureTime(gpuBFSFunction, repeats);

    double cpuCC = measureTime(cpuCCFunction, repeats);
    double gpuCC = measureTime(gpuCCFunction, repeats);

    bool bfsOK = (cpuDist == gpuDist);
    bool ccOK = (cpuLab == gpuLab);

    printf("Graph structure : %s\n", structure);
    printf("Vertices        : %d\n", g.n);
    printf("Undirected edges: %d\n", g.m / 2);
    printf("BFS verification: %s\n", bfsOK ? "PASS" : "FAIL");
    printf("CC verification : %s\n\n", ccOK ? "PASS" : "FAIL");

    printf("%-24s %12s %12s %12s\n",
           "Algorithm", "CPU(ms)", "GPU(ms)", "Speedup");

    printf("%-24s %12.4f %12.4f %11.3fx\n",
           "BFS", cpuBFS, gpuBFS, cpuBFS / gpuBFS);

    printf("%-24s %12.4f %12.4f %11.3fx\n",
           "Connected Components", cpuCC, gpuCC, cpuCC / gpuCC);

    printf("\nTest result: %s\n\n",
           (bfsOK && ccOK) ? "PASS" : "FAIL");

    if (!bfsOK || !ccOK) {
        printf("CPU and GPU results do not match.\n");
        exit(1);
    }
}

void runTestEvaluation() {
    const int repeats = 3;
    int passed = 0;
    int total = 0;

    printf("CUDA GraphBLAS Performance Evaluation\n\n");
    printf("Graph structure: Random connected sparse\n");
    printf("Execution times are medians of %d runs.\n\n", repeats);

    const int randomSizes[] = {1024,4096,16384,65536,262144,524288,1048576,2097152};

    for (int n : randomSizes) {
        Graph g;

        randomConnectedGraph(n, n * 5, g);

        evaluateGraph("Random connected sparse", g, 0, repeats);

        passed++;
        total++;
    }

    printf("Total graphs evaluated : %d\n", total);
    printf("Graphs passed          : %d\n", passed);
    printf("Result                 : %s\n",passed == total ? "ALL TEST CASES PASSED" : "SOME TESTS FAILED");
}

int main() {
    runTestEvaluation();
    return 0;
}


