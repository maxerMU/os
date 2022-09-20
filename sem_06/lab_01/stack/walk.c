#include "walk.h"

int print_file_pos(char *filename, size_t offset, size_t inode) {
  printf(" ");

  if (offset) {
    if (offset > 0)
      for (size_t i = 0; i < (offset - 1); i++) {
        printf("│");
        for (size_t j = 0; j < PRINT_WIDTH; j++)
          printf(" ");
      }
    printf("├");
    for (size_t i = 0; i < PRINT_WIDTH; i++)
      printf("─");
  }

  printf("%s %zu\n", filename, inode);

  return 0;
}

char *joinpath(char *base, char *file) {
  int len = strlen(base);
  char *path = malloc(len + strlen(file) + 2);

  if (!path)
    exit(ALLOC_ERROR);

  strcpy(path, base);
  path[len] = '/';
  strcpy(path + len + 1, file);

  return path;
}

static char *get_dynamic_str(char *string, size_t size) {
  char *dynamic_str = malloc(size + 1);

  if (!dynamic_str)
    exit(ALLOC_ERROR);

  strcpy(dynamic_str, string);
  return dynamic_str;
}

static int visit_file(stack_t *stack, size_t depth, char *curr_path,
                      char *curr_file, size_t inode) {
  struct stat statbuf;
  char *path = joinpath(curr_path, curr_file);

  if (lstat(path, &statbuf) == -1)
    return LSTAT_ERROR;

  if (S_ISDIR(statbuf.st_mode) != 0) {
    elem_t element = {path, depth};
    push(stack, element);
    return 0;
  }

  free(path);
  return print_file_pos(curr_file, depth, inode);
}

static int visit_dir(stack_t *stack, elem_t current, DIR *dp) {
  char *file = strrchr(current.dir, '/');
  if ((file))
    file++;
  else
    file = current.dir;
  struct dirent *dirp = NULL;

  struct stat statbuf;
  if (lstat(current.dir, &statbuf) == -1)
    return LSTAT_ERROR;

  print_file_pos(file, current.depth, statbuf.st_ino);

  if ((dp = opendir(current.dir)) != NULL) {
    while ((dirp = readdir(dp)) != NULL)
      if (strcmp(dirp->d_name, ".") != 0 && strcmp(dirp->d_name, "..") != 0)
        visit_file(stack, current.depth + 1, current.dir, dirp->d_name,
                   dirp->d_ino);
  }

  return 0;
}

int walk(char *dir) {
  stack_t *stack = create_stack();
  if (!stack)
    exit(ALLOC_ERROR);

  DIR *dp = NULL;
  size_t depth = 0;

  char *fullpath = get_dynamic_str(dir, PATH_MAX + 1);
  elem_t current = {fullpath, depth};

  if (push(stack, current))
    exit(ALLOC_ERROR);

  while (!is_empty(stack)) {
    current = pop(stack);

    visit_dir(stack, current, dp);
    free(current.dir);

    if (dp != NULL && closedir(dp) == -1)
      fprintf(stderr, "Can't close directory %s\n", fullpath);
  }

  destroy_stack(stack);
  return 0;
}
