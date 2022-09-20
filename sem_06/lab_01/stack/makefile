CC=gcc
CFLAGS=-std=gnu99 -Wall -Werror -Wpedantic -Wextra

TRASH=*.o *.exe

.PHONY: clean

app.exe: main.o stack.o walk.o
	$(CC) $(CFLAGS) -o $@ $^
	
main.o: main.c
	$(CC) $(CFLAGS) -c $<
	
stack.o: stack.c
	$(CC) $(CFLAGS) -c $<
	
walk.o: walk.c
	$(CC) $(CFLAGS) -c $<
	
clean:
	rm -f $(TRASH)
