#include <stdlib.h>
#include <stdio.h>
#include <dirent.h>
#include <string.h>
#include <limits.h>
#include <sys/stat.h>

typedef int Myfunc(const char *, const struct stat *, int);

static Myfunc myfunc;
static int myftw(char *, Myfunc *);
static int dopath(Myfunc *);

static long nreg, ndir, nblk, nchr, nfifo, nslink, nsock, ntot;


int main(int argc, char *argv[])
{
	setbuf(stdout, NULL);
	int ret;
	
	if (argc != 2)
	{
		printf("Использование: ./app.exe <начальный_каталог>\n");
		exit(-1);
	}
		
	ret = myftw(argv[1], myfunc);
	if (ret)
		exit(-1);

	ntot = nreg + ndir + nblk + nchr + nfifo + nslink + nsock;
	if (ntot == 0)
		ntot = 1;
	printf("обычные файлы                          %7ld, %5.2f %%\n", nreg, nreg * 100.0 / ntot);
	printf("каталоги                               %7ld, %5.2f %%\n", ndir, ndir * 100.0 / ntot);
	printf("специальные файлы блочных устройств    %7ld, %5.2f %%\n", nblk, nblk * 100.0 / ntot);
	printf("специальные файлы символьных устройств %7ld, %5.2f %%\n", nchr, nchr * 100.0 / ntot);
	printf("FIFO                                   %7ld, %5.2f %%\n", nfifo, nfifo * 100.0 / ntot);
	printf("символические ссылки                   %7ld, %5.2f %%\n", nslink, nslink * 100.0 / ntot);
	printf("сокеты                                 %7ld, %5.2f %%\n", nsock, nsock * 100.0 / ntot);
	
	exit(0);
}

#define FTW_F 1
#define FTW_D 2
#define FTW_DNR 3
#define FTW_NS 4

static char *fullpath;
static size_t pathlen;

static int myftw(char *pathname, Myfunc *func)
{
	pathlen = strlen(pathname) + 1;
	fullpath = malloc(pathlen * sizeof(char));
	if (!fullpath)
	{
		printf("ошибка при вызове alloc.\n");
		return -1;
	}
	
	strcpy(fullpath, pathname);
	return dopath(func);
}

static int dopath(Myfunc* func)
{
	struct stat statbuf;
	struct dirent *dirp;
	DIR *dp;
	int ret;
	size_t n;
	
	if (lstat(fullpath, &statbuf) == -1)
		return func(fullpath, &statbuf, FTW_NS);
		
	if (S_ISDIR(statbuf.st_mode) == 0) 
		return func(fullpath, &statbuf, FTW_F);
	
	if ((ret = func(fullpath, &statbuf, FTW_D)) != 0)
		return ret;
		
	n = strlen(fullpath);
	if (n + NAME_MAX + 2 > pathlen) 
	{
		pathlen *= 2;
		if ((fullpath = realloc(fullpath, pathlen)) == NULL)
		{
			printf("ошибка вызова realloc\n");
			return -1;
		}
	}
	
	fullpath[n++] = '/';
	fullpath[n] = 0;
	if ((dp = opendir(fullpath)) == NULL)
		return func(fullpath, &statbuf, FTW_DNR);
		
	while ((dirp = readdir(dp)) != NULL) 
	{
		if (strcmp(dirp->d_name, ".") == 0 ||
			strcmp(dirp->d_name, "..") == 0)
				continue;
		strcpy(&fullpath[n], dirp->d_name);
		if ((ret = dopath(func)) != 0)
			break;
	}
	fullpath[n-1] = 0;

	if (closedir(dp) == -1)
	{
		printf("невозможно закрыть каталог %s\n", fullpath);
		return -1;
	}
		
	return ret;
}

static int myfunc(const char *pathname, const struct stat *statptr, int type)
{
	switch (type) 
	{
		case FTW_F:
		switch (statptr->st_mode & S_IFMT) 
		{
			case S_IFREG: nreg++; break;
			case S_IFBLK: nblk++; break;
			case S_IFCHR: nchr++; break;
			case S_IFIFO: nfifo++; break;
			case S_IFLNK: nslink++; break;
			case S_IFSOCK: nsock++; break;
			case S_IFDIR: 
				printf("признак S_IFDIR для %s\n", pathname);
				return -1;
		}
		break;
		
		case FTW_D:
			ndir++; 
			break;
		case FTW_DNR:
			printf("закрыт доступ к каталогу %s\n", pathname);
			return -1;
		case FTW_NS:
			printf("ошибка вызова функции stat для %s\n", pathname);
			return -1;
		default:
			printf("неизвестный тип %d для файла %s\n", type, pathname);
			return -1;
	}
	
	return 0;
}
