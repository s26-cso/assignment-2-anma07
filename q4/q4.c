#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main() {
    char op[16];
    int num1, num2;
    void *handle = NULL;
    int (*operation_func)(int, int);
    char lib_path[32];

    while (scanf("%s %d %d", op, &num1, &num2) == 3) {
        
        snprintf(lib_path, sizeof(lib_path), "./lib%s.so", op);
        handle = dlopen(lib_path, RTLD_NOW);
        if (!handle) {
            fprintf(stderr, "Error: %s\n", dlerror());
            continue;
        }

        dlerror();

        operation_func = (int (*)(int, int))dlsym(handle, op);
        
        char *error = dlerror();
        if (error != NULL) {
            fprintf(stderr, "Symbol Error: %s\n", error);
            dlclose(handle);
            continue;
        }

        int result = operation_func(num1, num2);
        printf("%d\n", result);
        fflush(stdout);
        
        dlclose(handle);
    }

    return 0;
}