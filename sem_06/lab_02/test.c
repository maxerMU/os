#include <syslog.h>
#include <time.h>
#include <unistd.h>

int main(void) {
  openlog("mydaemonlog", LOG_CONS, LOG_DAEMON);
  syslog(LOG_ERR, "Wrong file decsriptors:\n");
  sleep(10);
}