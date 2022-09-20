#ifndef WALK_H
#define WALK_H

#include <stdlib.h>
#include <dirent.h>
#include <string.h>
#include <limits.h>
#include <sys/stat.h>

#include "stack.h"

#define LSTAT_ERROR 2
#define ALLOC_ERROR 3

int walk(char *dir);

#endif
