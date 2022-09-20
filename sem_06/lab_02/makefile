CC=gcc
CFLAGS=-std=gnu99 -Wall -Werror -Wpedantic -Wextra
LFLAGS=-pthread

TRASH=*.o *.exe

.PHONY: clean

app.exe: main.o
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $^
	
main.o: main.c
	$(CC) $(CFLAGS) -c $<
	
clean:
	rm -f $(TRASH)
