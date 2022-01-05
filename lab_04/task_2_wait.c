#include <stdio.h>
#include "stdlib.h"
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define FORK_ERROR_CODE 1

#define CHILDS_COUNT 2
#define CHILD_SLEEP 4

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

            sleep(CHILD_SLEEP);

            printf("Child №%zu died\n", i);
            exit(EXIT_SUCCESS);
        }
    }

    // parent part after all forks
    for (size_t i = 0; i < CHILDS_COUNT; i++)
    {
        int status;
        pid_t childpid = wait(&status);

        if (WIFEXITED(status))
        {
            printf("child process %d has been finished correctly with exit code %d\n", childpid, WEXITSTATUS(status));
        }
        else if (WIFSIGNALED(status))
        {
            printf("child process %d has been finished by signal %d\n", childpid, WTERMSIG(status));
        }
        else if (WIFSTOPPED(status))
        {
            printf("child process %d has been stopped by signal %d\n", childpid, WSTOPSIG(status));
        }
    }

    puts("Parent process died");
    exit(EXIT_SUCCESS);
}