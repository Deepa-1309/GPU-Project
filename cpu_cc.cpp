
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct Graph {
    int vertices;
    int edges;
    vector<int> rowPtr;
    vector<int> colIdx;
};

vector<int> connectedComponentsCPU(const Graph& graph) {

    int V = graph.vertices;

    vector<int> labels(V);
    vector<int> newLabels(V);

    for (int i = 0; i < V; i++)
        labels[i] = i;

    bool changed = true;

    while (changed) {

        changed = false;
        newLabels = labels;

        for (int u = 0; u < V; u++) {

            int minimum = labels[u];

            for (int i = graph.rowPtr[u];
                 i < graph.rowPtr[u + 1]; i++) {

                int v = graph.colIdx[i];

                minimum = min(minimum, labels[v]);
            }

            newLabels[u] = minimum;

            if (newLabels[u] != labels[u])
                changed = true;
        }

        labels.swap(newLabels);
    }

    return labels;
}
