CC=gcc
FLAGS=-Wall -Werror -Wpedantic -Wextra

TRASH=*.out *.o *.exe

.PHONY: clean

app.exe: main.o
	$(CC) $(FLAGS) -o $@ $<
	
main.o: main.c
	$(CC) $(FLAGS) -c -o $@ $<
	
clean:
	rm -f $(TRASH)
