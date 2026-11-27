
#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <string>

using namespace std;

struct Graph {
    int n;
    int m;
    vector<int> rp;
    vector<int> ci;
};

void buildCSR(int n, vector<pair<int,int>>&edges,Graph& g){
    sort(edges.begin(),edges.end());
    edges.erase(unique(edges.begin(),edges.end()),edges.end());

    g.n = n;
    g.m = 0;
    g.rp.assign(n+1,0);

    for(const auto& edge : edges){
        int u = edge.first;
        int v = edge.second;
        
        if(u==v || u<0 || v<0 || u>=n || v>=n) continue;

        g.rp[u+1]++;
        g.rp[v+1]++;
        g.m += 2;
    }

    for (int i = 1; i <= n; i++)
        g.rp[i] += g.rp[i - 1];

    g.ci.resize(g.m);

    vector<int> position = g.rp;

    for (const auto& edge : edges) {
        int u = edge.first;
        int v = edge.second;

        if (u == v || u < 0 || v < 0 || u >= n || v >= n)
            continue;

        g.ci[position[u]++] = v;
        g.ci[position[v]++] = u;
    }

    for (int i = 0; i < n; i++) {
        sort(g.ci.begin() + g.rp[i],g.ci.begin() + g.rp[i + 1]);
    }
}

void randomConnectedGraph(int n, int edgeCount, Graph& g) {
    if (n < 1)
        return;

    vector<pair<int, int>> edges;
    edges.reserve(edgeCount);

    mt19937 rng(12345 + n);

    for (int i = 1; i < n; i++) {
        uniform_int_distribution<int> parent(0, i - 1);
        int p = parent(rng);
        edges.push_back({min(i, p), max(i, p)});
    }

    long long maxEdges = (long long)n * (n - 1) / 2;
    edgeCount = (int)min((long long)edgeCount, maxEdges);
    edgeCount = max(edgeCount, n - 1);

    unordered_set<uint64_t> used;
    used.reserve((size_t)edgeCount * 2);

    for (const auto& edge : edges) {
        uint64_t key = (uint64_t)edge.first * n + edge.second;
        used.insert(key);
    }

    uniform_int_distribution<int> vertex(0, n - 1);

    while ((int)edges.size() < edgeCount) {
        int u = vertex(rng);
        int v = vertex(rng);

        if (u == v)
            continue;

        if (u > v)
            swap(u, v);

        uint64_t key = (uint64_t)u * n + v;

        if (used.insert(key).second)
            edges.push_back({u, v});
    }

    buildCSR(n, edges, g);
}


