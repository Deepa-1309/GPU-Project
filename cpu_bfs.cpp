
#include <iostream>
#include <vector>
#include <queue>

using namespace std;

struct Graph {
    int vertices;
    int edges;
    vector<int> rowPtr;
    vector<int> colIdx;
};

vector<int> bfsCPU(const Graph& graph, int source) {

    int V = graph.vertices;

    vector<int> distance(V, -1);
    queue<int> q;

    distance[source] = 0;
    q.push(source);

    while (!q.empty()) {

        int u = q.front();
        q.pop();

        for (int i = graph.rowPtr[u];
             i < graph.rowPtr[u + 1]; i++) {

            int v = graph.colIdx[i];

            if (distance[v] == -1) {

                distance[v] = distance[u] + 1;
                q.push(v);
            }
        }
    }

    return distance;
}
