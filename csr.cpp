
#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <string>

using namespace std;

struct Graph {
    int vertices;
    int edges;
    vector<int> rowPtr;
    vector<int> colIdx;
};

bool readGraph(const string& filename, Graph& graph) {

    ifstream file(filename);

    if (!file.is_open()) {
        cout << "Cannot open graph file\n";
        return false;
    }

    int V, E;
    file >> V >> E;

    if (!file || V <= 0 || E < 0) {
        cout << "Invalid graph information\n";
        return false;
    }

    vector<vector<int>> adj(V);

    for (int i = 0; i < E; i++) {

        int u, v;
        file >> u >> v;

        if (!file || u < 0 || u >= V || v < 0 || v >= V) {
            cout << "Invalid edge\n";
            return false;
        }

        if (u == v)
            continue;

        adj[u].push_back(v);
        adj[v].push_back(u);
    }

    graph.vertices = V;

    graph.rowPtr.resize(V + 1);
    graph.rowPtr[0] = 0;

    for (int i = 0; i < V; i++) {

        sort(adj[i].begin(), adj[i].end());

        adj[i].erase(
            unique(adj[i].begin(), adj[i].end()),
            adj[i].end()
        );

        graph.rowPtr[i + 1] =
            graph.rowPtr[i] + adj[i].size();
    }

    graph.colIdx.resize(graph.rowPtr[V]);

    for (int i = 0; i < V; i++) {

        int index = graph.rowPtr[i];

        for (int v : adj[i]) {
            graph.colIdx[index++] = v;
        }
    }

    graph.edges = graph.colIdx.size() / 2;

    return true;
}
