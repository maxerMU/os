#include <iostream>
#include <fstream>
#include <cstring>
#include <unistd.h>

int read_array(int **array, size_t *array_len, const char *file_name)
{
    std::ifstream f(file_name);

    if (!(f >> *array_len))
        return 1;
    
    *array = new int[*array_len];

    for (size_t i = 0; i < *array_len; i++)
        if (!(f >> (*array)[i]))
            return 1;
    
    f.close();
    
    return 0;
}

void sort_array(int *array, size_t array_len, int dest)
{
    for (size_t i = 0; i < array_len - 1; i++)
        for (size_t j = 0; j < array_len - i - 1; j++)
            if (array[j] * dest > array[j + 1] * dest)
            {
                int temp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = temp;
            }
}

void print_array(int *a, size_t len)
{
    for (size_t i = 0; i < len; i++)
        std::cout << a[i] << " ";

    std::cout << std::endl;
}

int main(int argc, char **argv)
{
    sleep(1);
    printf("-----------------------------------------------------------\n"
           "This program sorts array in ascending or descending order\n\n");
    if (argc != 3)
        return 1;
    
    int *array;
    size_t array_len;
    int rc = read_array(&array, &array_len, argv[1]);
    if (rc)
        return rc;

    printf("Array before sort\n");
    print_array(array, array_len);
    
    
    if (strcmp(argv[2], "b") == 0)
        sort_array(array, array_len, 1);
    else if (strcmp(argv[2], "l") == 0)
        sort_array(array, array_len, -1);

    puts("array after sort");
    print_array(array, array_len);
    puts("-----------------------------------------------------------");
    
    return 0;
}