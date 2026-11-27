NVCC = nvcc
FLAGS = -O2 -std=c++17 -arch=sm_80

all: gb

gb: src/main.cu src/csr.cpp src/cpu_bfs.cpp src/cpu_cc.cpp src/gpu_graphblas.cu
	$(NVCC) $(FLAGS) src/main.cu -o gb

test: gb
	./gb

clean:
	rm -f gb
