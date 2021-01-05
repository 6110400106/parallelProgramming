#include<stdio.h>

__global__ void parallel_vector_add(int* d_a, int* d_b, int* d_c, int* d_n) {
	int i = (blockIdx.x*blockDim.x) + threadIdx.x;
	// printf("I am thread #%d\n", i);
	if(i < *d_n) {
		printf("I am thread #%d. and about to computer c[%d].\n", i, i);
		d_c[i] = d_a[i]+d_b[i];
	} else {
		printf("I am thread #%d and doing nothing.\n", i);
	}
}

int main() {
	// allocate and initialize host memory
	int n;
	scanf("%d", &n);

	int h_a[n];
      	int h_b[n];
	int h_c[n];

	for(int i = 0; i < n; i++) {
		h_a[i] = i;
		h_b[i] = n-1;
	}

	// Part 1: Copy data from host to device
	// allocate device memory for a, b, and c
	int *d_a, *d_b, *d_c, *d_n;
	// copy a and b to device memory
	cudaMalloc((void **) &d_a, n*sizeof(int));
	cudaMalloc((void **) &d_b, n*sizeof(int));
	cudaMalloc((void **) &d_c, n*sizeof(int));
	cudaMalloc((void **) &d_n, sizeof(int));
	
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaMemcpy(d_a, &h_a, n*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, &h_b, n*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_n, &n, sizeof(int), cudaMemcpyHostToDevice);

	// Part 2: Kernel launch
	// kernel launch code which let the device performs the actual vector addtion
	int numB;	// number of block
	numB = n%512 ? (n/512)+1 : n/512;	// 512 is a number of thread per block.

	cudaEventRecord(start);
	// 512 is a number of thread per block which can be change without a problem.
	parallel_vector_add<<<numB, 512>>>(d_a, d_b, d_c, d_n);
	cudaEventRecord(stop);
	cudaDeviceSynchronize();

	// Part 3: Copy data from device back to host, and free all data allocate on device
	cudaMemcpy(&h_c, d_c, n*sizeof(int), cudaMemcpyDeviceToHost);
	
	cudaEventSynchronize(stop);
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);

	for(int i = 0; i < n; i++) {
		printf("%d ", h_c[i]);
	}
	printf("\n Time used: %f milliseconds\n", milliseconds);
}
