#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define PREFIX_SIZE 256
	

int dopath(const char* filename)
{
	static char prefix[PREFIX_SIZE] = "";

	struct stat statbuf;

	int ret = 0;
	switch (lstat(filename, &statbuf)) {
		case EACCES:
			perror("Search permission is denied");
			return -1;
		case EBADF:
			perror("fd is bad");
			return -1;
		case EFAULT:
			perror("Bad address");
			return -1;
		case ELOOP:
			perror("Too many symbolic links encountered while traversing the path");
			return -1;
		case ENAMETOOLONG:
			perror("path is too long");
			return -1;
		case ENOENT:
			perror("A component of path does not exist, or path is an empty string");
			return -1;
		case ENOMEM:
			perror("Out of memory");
			return -1;
		case ENOTDIR:
			perror("A component of the path prefix of path is not a directory");
			return -1;
		case EOVERFLOW:
			perror("path or fd refers to a file whose size, inode number, or number of blocks cannot be represented in, respectively, the types off_t, ino_t, or blkcnt_t");
			return -1;
	}

	if (S_ISDIR(statbuf.st_mode)) {
		printf("%s/ \t[inode=%lu]\n", filename, statbuf.st_ino);
	} else {
		printf("%s \t[inode=%lu]\n", filename, statbuf.st_ino);
		return 0;
	}

	DIR* dp = opendir(filename);

	if (dp == NULL) {
		perror("opendir");
		return -1;
	}

	chdir(filename);

	struct dirent* dirp = readdir(dp);
	struct dirent* next = readdir(dp);

	while (dirp != NULL && ret == 0) {
		if (strcmp(dirp->d_name, ".") != 0 &&
		    strcmp(dirp->d_name, "..") != 0) {
			int l = strlen(prefix);

			if (next) {
				printf("%s-- ", prefix);
				strncat(prefix, "|  ", PREFIX_SIZE - l - 1);
			} else {
				printf("%s-- ", prefix);
				strncat(prefix, "   ", PREFIX_SIZE - l - 1);
			}

			ret = dopath(dirp->d_name);
			prefix[l] = 0;
		}

		dirp = next;
		next = readdir(dp);
	}

	chdir("..");

	if (closedir(dp) < 0) {
		perror("closedir");
	}

	return ret;
}

int main(int argc, char* argv[])
{
	int ret = -1;
	if (argc != 2) {
		printf("ERROR, wrong arguments.\nUse: ./app <dir>\n");
		exit(-1);
	}

	if (dopath(argv[1]) == -1) {
		perror("dopath");
		return 1;
	}

	return 0;
}
