#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>

/*
Simple test program which can show how read/write buffer size
affects to the number of syscalls.

Compile:
gcc -Wall bufio.c -o bufio

Check time and syscalls count (linux only, due strace usage):
$ strace -c ./bufio 1000 1000000 < /dev/random
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 59.95    0.008787           8      1001           read
 40.05    0.005869           5       999           write
  0.00    0.000000           0         2           close
...

$ strace -c ./bufio 10000 1000000 < /dev/random
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 82.16    0.005187          51       101           read
 10.55    0.000666           6        99           write
  2.93    0.000185         185         1           execve
...

$ strace -c ./bufio 100000 1000000 < /dev/random
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 99.41    0.000671          61        11           read
  0.59    0.000004           0         9           write
  0.00    0.000000           0         2           close
...

$ strace -c ./bufio 1000000 1000000 < /dev/random
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
  0.00    0.000000           0         2           read
  0.00    0.000000           0         2           close
  0.00    0.000000           0         8           mmap
  0.00    0.000000           0         4           mprotect
...
*/
int main(int argc, char** argv) {
  int BUFSIZE = atoi(argv[1]);
  int MAX = atoi(argv[2]);

  char buf[BUFSIZE];
  int n = 0;
  int rn = 0;
  int fd = open("/dev/null", O_WRONLY, 0);
  while( (n = read(0, buf, BUFSIZE)) > 0 && (rn += BUFSIZE) < MAX) {
    write(fd, buf, BUFSIZE);
  }

  return 0;
}
