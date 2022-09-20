#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

#define FORK_ERROR_CODE 1
#define EXEC_ERROR_CODE 2
#define PIPE_ERROR_CODE 3

#define CHILDS_COUNT 2
#define CHILD_SLEEP 4
#define WAITING_SIGNAL_SLEEP 2

int flag = 0;
void sig_handler(int signal)
{
    flag = 1;
    printf("signal %d has been catched\n", signal);
}

int main(void)
{
    printf("Parent PID: %d, Parent group ID: %d\n", getpid(), getpgrp());

    const char *messages[CHILDS_COUNT] = {"abdx\n", "eqwrt ewrq sdjka\n"};

    signal(SIGTSTP, sig_handler);
    printf("enter cntrl + z to enable writing\n");
    sleep(WAITING_SIGNAL_SLEEP);

    int fd[2];
    if (pipe(fd) == -1)
    {
        perror("pipe error");
        exit(PIPE_ERROR_CODE);
    }

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

            if (flag) {
                close(fd[0]);
                write(fd[1], messages[i], strlen(messages[i]));
            }

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

    close(fd[1]);
    char buf;
    printf("first message: ");
    while (read(fd[0], &buf, 1) > 0 && buf != '\n')
    {
        printf("%c", buf);
    }
    printf("\n");

    printf("second message: ");
    while (read(fd[0], &buf, 1) > 0 && buf != '\n')
    {
        printf("%c", buf);
    }
    printf("\n");

    printf("second message: ");
    while (read(fd[0], &buf, 1) > 0 && buf != '\n')
    {
        printf("%c", buf);
    }

    
    puts("Parent process died");
    exit(EXIT_SUCCESS);
}