
#include <cuda_runtime.h>
#include <vector>
#include <cstdio>
#include <cstdlib>

#define TPB 256
#define INF 0x3fffffff

using namespace std;

struct BoolSR {
    __device__ static int zero() {
        return 0;
    }

    __device__ static int add(int a, int b) {
        return a | b;
    }

    __device__ static int mul(int a, int b) {
        return a & b;
    }
};

struct MinPlusSR {
    __device__ static int zero() {
        return INF;
    }

    __device__ static int add(int a, int b) {
        return a < b ? a : b;
    }

    __device__ static int mul(int a, int b) {
        return a + b;
    }
};

template <class SR>
__global__ void mxv(int n, const int *rp, const int *ci,const int *x, int *y, int w, const int *mask) {

    int v = blockIdx.x * blockDim.x + threadIdx.x;

    if (v >= n)
        return;

    if (mask != NULL && mask[v]) {
        y[v] = SR::zero();
        return;
    }

    int acc = SR::zero();

    for (int e = rp[v]; e < rp[v + 1]; e++) {
        acc = SR::add(acc, SR::mul(w, x[ci[e]]));
    }

    y[v] = acc;
}

__global__ void bfsApply(int n, const int *y, int *vis,int *dist, int *front, int lev, int *changed) {

    int v = blockIdx.x * blockDim.x + threadIdx.x;

    if (v >= n)
        return;

    if (y[v] && !vis[v]){
        vis[v] = 1;
        dist[v] = lev;
        front[v] = 1;
        atomicExch(changed, 1);
    }
    else{
        front[v] = 0;
    }
}

__global__ void ccApply(int n, const int *y, int *lab, int *changed) {

    int v = blockIdx.x * blockDim.x + threadIdx.x;

    if (v >= n)
        return;

    if (y[v] < lab[v]) {
        lab[v] = y[v];
        atomicExch(changed, 1);
    }
}

int* toDev(vector<int> &h) {
    int *d;

    cudaMalloc(&d, h.size() * sizeof(int));
    cudaMemcpy(d, h.data(), h.size() * sizeof(int),cudaMemcpyHostToDevice);

    return d;
}

vector<int> bfsGPU(Graph &g, int src) {

    int n = g.n;
    int h;

    int blocks = (n + TPB - 1) / TPB;

    vector<int> front(n, 0);
    vector<int> vis(n, 0);
    vector<int> dist(n, -1);

    front[src] = 1;
    vis[src] = 1;
    dist[src] = 0;

    int *rp = toDev(g.rp);
    int *ci = toDev(g.ci);
    int *dfront = toDev(front);
    int *dvis = toDev(vis);
    int *ddist = toDev(dist);

    int *y, *dch;

    cudaMalloc(&y, n * sizeof(int));
    cudaMalloc(&dch, sizeof(int));

    int lev = 1;

    while (1) {

        h = 0;

        cudaMemcpy(dch, &h, sizeof(int), cudaMemcpyHostToDevice);

        mxv<BoolSR><<<blocks, TPB>>>(n, rp, ci, dfront, y, 1, dvis);

        bfsApply<<<blocks, TPB>>>(n, y, dvis, ddist, dfront, lev, dch);

        cudaMemcpy(&h, dch, sizeof(int), cudaMemcpyDeviceToHost);

        if (!h)
            break;

        lev++;
    }

    cudaMemcpy(dist.data(), ddist, n * sizeof(int),cudaMemcpyDeviceToHost);

    cudaFree(rp);
    cudaFree(ci);
    cudaFree(dfront);
    cudaFree(dvis);
    cudaFree(ddist);
    cudaFree(y);
    cudaFree(dch);

    return dist;
}

vector<int> ccGPU(Graph &g) {

    int n = g.n;
    int h;

    int blocks = (n + TPB - 1) / TPB;

    vector<int> lab(n);

    for (int i = 0; i < n; i++) {
        lab[i] = i;
    }

    int *rp = toDev(g.rp);
    int *ci = toDev(g.ci);
    int *dlab = toDev(lab);

    int *y, *dch;

    cudaMalloc(&y, n*sizeof(int));
    cudaMalloc(&dch, sizeof(int));

    while (1) {

        h = 0;

        cudaMemcpy(dch, &h, sizeof(int), cudaMemcpyHostToDevice);

        mxv<MinPlusSR><<<blocks, TPB>>>(n, rp, ci, dlab, y, 0, NULL);

        ccApply<<<blocks, TPB>>>(n, y, dlab, dch);

        cudaMemcpy(&h, dch, sizeof(int), cudaMemcpyDeviceToHost);

        if (!h)
            break;
    }

    cudaMemcpy(lab.data(), dlab, n*sizeof(int),cudaMemcpyDeviceToHost);

    cudaFree(rp);
    cudaFree(ci);
    cudaFree(dlab);
    cudaFree(y);
    cudaFree(dch);

    return lab;
}

