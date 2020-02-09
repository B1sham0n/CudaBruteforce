#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <fstream>
#include <iostream>
#include "../lib/md5.h"
#include "../libs/Bluebird Library/BB.h"
#include "../libs/cuda-hashing-algos-master/config.h"
#include "../libs/cuda-hashing-algos-master/md5.cuh"
#include "md5-cuda.cuh"
#include "md5-cuda.cu"
using namespace std;

cudaError_t addWithCuda(int* c, const int* a, const int* b, unsigned int size);

//������ ������������ ��� ������� ��� ������� � ��������, �� ��� �� ���������
class __vector {
public:
    //char password[size];
    char* password;
    int* passw;
    int size;
    __device__ __host__ __vector(string pass) {
        size = pass.length();
        password = new char[size];
        strcpy(password, pass.c_str());

        passw = new int[size];
        for (int i = 0; i < size; i++)
            passw[i] = password[i];

    }

};

//���������� ������ � ��������� �� �������� � ��������� ����
thrust::host_vector<char> GetLetters() {
    vector<char> letters;
    unsigned char a;
    for (a = 65; a < 91; ++a) {
        letters.push_back(a);
    }
    for (a = 97; a < 123; ++a)
    {
        letters.push_back(a);
    }

    return letters;
}

thrust::host_vector<string> combinations;
//�������� ��� �������� ���������� �������� chars
void printCombinations(const thrust::host_vector<char>& chars, unsigned size, thrust::host_vector<char>& line) {
    for (unsigned i = 0; i < chars.size(); i++) {
        line.push_back(chars[i]);
        if (size <= 1) { // Condition that prevents infinite loop in recursion
            string pass;
            for (const auto& j : line)
                pass += j;
            //cout << pass << endl;
            combinations.push_back(pass);
            line.erase(line.end() - 1);
        }
        else {
            printCombinations(chars, size - 1, line); // Recursion happens here
            line.erase(line.end() - 1);
        }
    }
}
/*void printCombinations(const thrust::host_vector<char>& chars, unsigned size, thrust::host_vector<char>& line, ofstream& myfile) {
    for (unsigned i = 0; i < chars.size(); i++) {
        line.push_back(chars[i]);
        if (size <= 1) { // Condition that prevents infinite loop in recursion
            for (const auto& j : line)
                myfile << j; // Simplified print to keep code shorter
            myfile << "\n";
            line.erase(line.end() - 1);
        }
        else {
            printCombinations(chars, size - 1, line, myfile); // Recursion happens here
            line.erase(line.end() - 1);
        }
    }
}*/
thrust::host_vector<string> FileToVector(string file_name) {

    // Open the File
    std::ifstream in(file_name);
    thrust::host_vector<string> pass_vector;
    string str;
    while (std::getline(in, str))
    {
        // Line contains string of length > 0 then save it in vector
        if (str.size() > 0)
            pass_vector.push_back(str);
    }

    return pass_vector;
}

//�����, ������� ���������� � ����� �� GPU. ������ ������� ����� ������ � ������� ������ � ��� ������(���-�� ������� = ���-�� �������) 
__global__ void SearchPassword(char **passwords, int *sizes) {
    //printf("Size: %d \n", sizes[threadIdx.x]);
    //printf("Size: %c \n", passwords[0][0]);
   // MD5 md5;
    //cout << md5("hello");
    //printf("Size: %c \n", md5("hello"));
    for(int i = 0; i < sizes[threadIdx.x]; i++)
        printf("%c; %d \n", passwords[threadIdx.x][i], threadIdx.x);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int main()
{
#pragma region MyRegion

    /*ofstream myfile;
    myfile.open("example.txt");

    vector<char> numbers = { 'A', '1', 'B', '3' };
    for (int i = 1; i < 5; i++) {
        unsigned size = i;
        thrust::host_vector<char> line;
        printCombinations(GetLetters(), size, line, myfile);
    }
    cout << endl;
    myfile.close();
    */
    /*thrust::host_vector<string> passwords = FileToVector("example.txt");
    for each (string var in passwords)
    {
        cout << var << endl;
    }*/
#pragma endregion

    //������� �������� ������� �� ����� - FileToVector(file)
    //�������� ������ � ���� - printCombinations, ����� ����������� ������� ��� �����, ��� ���� ����
  
    //thrust::host_vector<string> passwords = FileToVector("example.txt");
    //cout << passwords.size() << endl;

    //�������� ���������� ������� � ��������, ������ ������� = ������, ����� ������ ����� ���� ���������� � ����������� � ������ sizes[����� ������]
    std::string data = "test";
    std::string data_hex_digest;

    md5 hash;
    hash.update(data.begin(), data.end());
    hash.hex_digest(data_hex_digest);

    std::cout << data_hex_digest << std::endl;

    MD5 md5;
    cout << md5("test");

   // mcm_cuda_md5_hash_batch(byte, word, out, outw);
    //cout << wrapper->getHashFromString("yoda");
    
    thrust::host_vector<char> pass;
    for (int i = 1; i < 3; i++) {
        unsigned size = i;
        thrust::host_vector<char> line;
        printCombinations(GetLetters(), size, line);
    }

    const int comb_lines = combinations.size();
    char** all_combinations_array = new char* [comb_lines];
    int* password_sizes = new int[comb_lines];

    for (int i = 0; i < comb_lines; i++) {
        string s = combinations[i]; 
        all_combinations_array[i] = new char[s.length()];
        strcpy(all_combinations_array[i], s.c_str());
        password_sizes[i] = s.length();
    }

    char** dev_all_combinations_array;//��������� �� ��������� ������, ������� �� ��������� � gpu
    cudaMalloc((void**)&dev_all_combinations_array, comb_lines * sizeof(char*));//�������� ������ �� ���������� � ��������� ��������� �� ��� � dev_device_passw. ������ �������� - ���-�� ������, �� ������ �������


    char* dev_line[10000];//��������� �� ���������� ������ ���������� ��������� lines, ����� � ���� ��������� ������ ������ ��������� ������� � ��������
    for (int i = 0; i < comb_lines; i++) {
        cudaMalloc((void**)&dev_line[i], sizeof(char) * password_sizes[i]);
        cudaMemcpy(dev_line[i], all_combinations_array[i], sizeof(char) * password_sizes[i], cudaMemcpyHostToDevice);
    }

    cudaMemcpy(dev_all_combinations_array, dev_line, sizeof(char*) * comb_lines, cudaMemcpyHostToDevice);//�������� � ��������� dev_device_passw ��������� �� ������ dev_line_passw

    int* dev_sizes;//��������� ��� �������� ������� � ��������� �����

    cudaMalloc((void**)&dev_sizes, sizeof(int) * comb_lines);//�������� ������ �������� � ������
    cudaMemcpy(dev_sizes, password_sizes, sizeof(int) * comb_lines, cudaMemcpyHostToDevice);//�������� ��������� �� ������ sizes 

    SearchPassword << <1, 100 >> > (dev_all_combinations_array, dev_sizes);//������ ������� ������� [1][10] (�.�. 1 ������ ������� �� 10 ������� = 10 �������), ������ ��� � ������ ����

#pragma region old

    /*
    const int lines = 10, columns = 4; 
    char** passw = new char* [lines];//������ � ��������
    int* sizes = new int[lines];//������ � ������� �����

    //������ ��������� ���������� �������, ����� ��������� ������
    for (int i = 0; i < lines; i++) {
        if (i % 2 == 0) {
            passw[i] = new char[columns];
            //col = 4;
            sizes[i] = 4;
        }
        else {
            passw[i] = new char[columns + 1];
            //col = 5;
            sizes[i] = 5;
        }
        for (int j = 0; j < sizes[i]; j++) {
            switch (j)
            {
            case 0:
                passw[i][j] = 'p';
                break;
            case 1:
                passw[i][j] = 'a';
                break;
            case 2:
                passw[i][j] = 's';
                break;
            case 3:
                passw[i][j] = 's';
                break;
            case 4:
                passw[i][j] = 'w';
                break;
            }
        }
    }
    //����� ������� � �������� ��� ��������
    /*
    for (int i = 0; i < lines; i++) {
        for (int j = 0; j < sizes[i]; j++)
        {
            cout << passw[i][j];
        }
        cout << endl;
    }
    

    char** dev_device_passw;//��������� �� ��������� ������, ������� �� ��������� � gpu
    cudaMalloc((void**)&dev_device_passw, lines * sizeof(char*));//�������� ������ �� ���������� � ��������� ��������� �� ��� � dev_device_passw. ������ �������� - ���-�� ������, �� ������ �������

    char* dev_line_passw[lines];//��������� �� ���������� ������ ���������� ��������� lines, ����� � ���� ��������� ������ ������ ��������� ������� � ��������
    for (int i = 0; i < lines; i++) {
        cudaMalloc((void**)&dev_line_passw[i], sizeof(char) * sizes[i]);
        cudaMemcpy(dev_line_passw[i], passw[i], sizeof(char) * sizes[i], cudaMemcpyHostToDevice);
    }

    cudaMemcpy(dev_device_passw, dev_line_passw, sizeof(char*) * lines, cudaMemcpyHostToDevice);//�������� � ��������� dev_device_passw ��������� �� ������ dev_line_passw

    int* dev_sizes;//��������� ��� �������� ������� � ��������� �����

    cudaMalloc((void**)&dev_sizes, sizeof(int) * lines);//�������� ������ �������� � ������
    cudaMemcpy(dev_sizes, sizes, sizeof(int) * lines,cudaMemcpyHostToDevice);//�������� ��������� �� ������ sizes 

    SearchPassword <<<1, 10 >>> (dev_device_passw, dev_sizes);//������ ������� ������� [1][10] (�.�. 1 ������ ������� �� 10 ������� = 10 �������), ������ ��� � ������ ����

    //����������� ���������� ������ �� GPU
    cudaFree(dev_device_passw);
    cudaFree(dev_sizes);
    cudaFree(dev_line_passw);
    */
#pragma endregion

    return 0;
}

//��� ��� ������ ���� ��� �������� �������, ����� ������������ ��� ������ �������� ���������� � GPU
__global__ void addKernel(int* c, const int* a, const int* b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
   
    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}


