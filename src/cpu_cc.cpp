#include <numeric>

int findRoot(vector<int> &p, int x) {
	while (p[x] != x) {
		p[x] = p[p[x]];
		x = p[x];
	}
	return x;
}

vector<int> ccCPU(Graph &g) {
	vector<int> p(g.n);
	iota(p.begin(), p.end(), 0);
	for (int v = 0; v < g.n; v++)
		for (int e = g.rp[v]; e < g.rp[v + 1]; e++) {
			int a = findRoot(p, v);
			int b = findRoot(p, g.ci[e]);
			if (a < b) p[b] = a;
			else if (b < a) p[a] = b;
		}
	for (int v = 0; v < g.n; v++) p[v] = findRoot(p, v);
	return p;
}
