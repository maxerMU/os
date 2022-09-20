#ifndef STACK_H
#define STACK_H

#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>

#define MIN_STACK_CAPACITY 16
#define PRINT_WIDTH 4

typedef struct 
{
	char *dir;
	size_t depth;
} elem_t;

typedef struct 
{
	elem_t *data;
	size_t size, capacity;
} stack_t;

stack_t* create_stack();

void destroy_stack(stack_t *stack);

int push(stack_t *stack, elem_t elem);

elem_t pop(stack_t *stack);

bool is_empty(stack_t *stack);

#endif
