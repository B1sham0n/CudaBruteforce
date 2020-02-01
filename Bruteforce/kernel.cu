#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <fstream>
#include <iostream>
#include "../libs/src/hl_md5.h"
using namespace std;

cudaError_t addWithCuda(int* c, const int* a, const int* b, unsigned int size);

//хотела использовать как обертку для массива с паролями, но так не сработало
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

//возвращает массив с алфавитом из строчных и заглавных букв
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

//печатает все варианты комбинаций символов chars
void printCombinations(const thrust::host_vector<char>& chars, unsigned size, thrust::host_vector<char>& line, ofstream& myfile) {
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
}
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

//метод, который передается в поток на GPU. просто выводит длину пароля у данного потока и сам пароль(кол-во потоков = кол-во паролей) 
__global__ void SearchPassword(char **passwords, int *sizes) {
    printf("Size: %d \n", sizes[threadIdx.x]);
    //printf("Size: %c \n", passwords[0][0]);
    for(int i = 0; i < sizes[threadIdx.x]; i++)
        printf("Passw: %c \n", passwords[threadIdx.x][i]);
}

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

    //считать варианты паролей из файла - FileToVector(file)
    //записать пароли в файл - printCombinations, потом планируется сделать без файла, это пока тест
  
    //thrust::host_vector<string> passwords = FileToVector("example.txt");
    //cout << passwords.size() << endl;

    //создание двумерного массива с паролями, строка массива = пароль, длина пароля может быть переменной и сохраняется в массив sizes[номер строки]
    const int lines = 10, columns = 4; 
    char** passw = new char* [lines];//массив с паролями
    int* sizes = new int[lines];//массив с длинами строк

    //просто рандомное заполнение массива, чтобы проверить работу
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
    //вывод массива с паролями для проверки
    /*
    for (int i = 0; i < lines; i++) {
        for (int j = 0; j < sizes[i]; j++)
        {
            cout << passw[i][j];
        }
        cout << endl;
    }
    */

    char** dev_device_passw;//указатель на двумерный массив, который мы передадим в gpu
    cudaMalloc((void**)&dev_device_passw, lines * sizeof(char*));//выделяем память на видеокарте и сохраняем указатель на нее в dev_device_passw. второй параметр - кол-во памяти, мб указан неверно

    char* dev_line_passw[lines];//указатель на одномерный массив указателей размерном lines, чтобы в него сохранить каждую строку исходного массива с паролями
    for (int i = 0; i < lines; i++) {
        cudaMalloc((void**)&dev_line_passw[i], sizeof(char) * sizes[i]);
        cudaMemcpy(dev_line_passw[i], passw[i], sizeof(char) * sizes[i], cudaMemcpyHostToDevice);
    }

    cudaMemcpy(dev_device_passw, dev_line_passw, sizeof(char*) * lines, cudaMemcpyHostToDevice);//копируем в указатель dev_device_passw указатель на память dev_line_passw

    int* dev_sizes;//указатель для передачи массива с размерами строк

    cudaMalloc((void**)&dev_sizes, sizeof(int) * lines);//выделяем память размером с массив
    cudaMemcpy(dev_sizes, sizes, sizeof(int) * lines,cudaMemcpyHostToDevice);//копируем указатель на массив sizes 

    SearchPassword <<<1, 10 >>> (dev_device_passw, dev_sizes);//запуск массива потоков [1][10] (т.е. 1 строка потоков из 10 потоков = 10 потоков), ошибка так и должна быть

    //освобождаем выделенную память на GPU
    cudaFree(dev_device_passw);
    cudaFree(dev_sizes);
    cudaFree(dev_line_passw);

    return 0;
}

//эти два метода были при создании проекта, можно использовать как пример передачи указателей в GPU
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


