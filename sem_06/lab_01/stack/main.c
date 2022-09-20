#include <stdio.h>

#include "walk.h"

#define INVALID_ARG 1

int main(int argc, char *argv[])
{
	if (argc != 2)
	{
		printf("Usage: ./app.exe <dir>\n");
		return INVALID_ARG;
	}
		
	return walk(argv[1]);
}
