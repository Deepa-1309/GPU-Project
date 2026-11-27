#include <queue>


vector<int> bfsCPU(Graph &g, int src) {
	vector<int> dist(g.n, -1);
	queue<int> q;
	dist[src] = 0;
	q.push(src);
	while (!q.empty()) {
		int u = q.front();
		q.pop();
		for (int e = g.rp[u]; e < g.rp[u + 1]; e++) {
			int v = g.ci[e];
			if (dist[v] == -1) {
				dist[v] = dist[u] + 1;
				q.push(v);
			}
		}
	}
	return dist;
}
