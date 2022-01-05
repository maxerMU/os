#include <stdio.h>
#include "stdlib.h"
#include <sys/types.h>
#include <unistd.h>

#define FORK_ERROR_CODE 1

#define CHILDS_COUNT 2
#define CHILD_SLEEP 2

int main(void)
{
    printf("Parent PID: %d, Parent group ID: %d\n", getpid(), getpgrp());

    for (size_t i = 0; i < CHILDS_COUNT; i++)
    {
        pid_t child_pid = fork();
        if (child_pid == -1)
        {
            perror("Can't fork");
            exit(FORK_ERROR_CODE);
        }
        else if (child_pid)
        {
            // parent part
            printf("Parent child №%zu pid: %d\n", i, child_pid);
        }
        else
        {
            // child part
            printf("Child №%zu pid: %d, ppid: %d, group ID: %d\n", i, getpid(), getppid(), getpgrp());

            // waiting for parent process finish
            sleep(CHILD_SLEEP);

            printf("Child №%zu new ppid: %d, new group: %d\n", i, getppid(), getpgrp());
            exit(EXIT_SUCCESS);
        }
    }

    puts("Parent process died");
    exit(EXIT_SUCCESS);
}