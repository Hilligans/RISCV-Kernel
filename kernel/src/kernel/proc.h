
#include <types.h>
#include <thread.h>

typedef struct proccess {

    int plock;

    int pid;

    THREAD mainThread;

    int childThreadCount;
    THREAD* subThread;

} PROCESS;
