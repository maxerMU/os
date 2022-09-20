#include "stack.h"

stack_t* create_stack()
{
	stack_t *stack = malloc(sizeof(stack_t));
	if (!stack)
		return NULL;
		
	stack->capacity = MIN_STACK_CAPACITY;
	stack->size = 0;
	

	stack->data = malloc(stack->capacity * sizeof(elem_t));
	if (!stack->data)
	{
		free(stack);
		return NULL;
	}

	
	return stack;
}

void destroy_stack(stack_t *stack)
{
	if (stack)
		free(stack->data);
		
	free(stack);
}

int push(stack_t *stack, elem_t elem)
{
	if (stack->size == stack->capacity)
	{
		stack->capacity *= 2;

		elem_t *tmp = realloc(stack->data, stack->capacity * sizeof(elem_t));
		if (!tmp)
			return EXIT_FAILURE;
			
		stack->data = tmp;
	}
	
	stack->data[stack->size++] = elem;
	
	return EXIT_SUCCESS;
}

elem_t pop(stack_t *stack)
{
	stack->size -= 1;
	return stack->data[stack->size];
}

bool is_empty(stack_t *stack)
{
	return !stack->size;
}
