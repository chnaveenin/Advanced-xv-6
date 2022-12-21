# Enhanced xv6
# Chekkapalli Naveen 2021101025
# Ch Sri Lakshmanarao 2021101011


# Requirments:
1. This assignment requires Linux environment(preferbly Ubuntu) to execute.

# Execution:
1. The assignment can be executed by running the command 
     ``` 
     make qemu SCHEDULER=<options>
     ```
2. For now the options are ```FCFS```, ```PBS```, ```LBS```, ```ROUNDROBIN ```. If Scheduler isn't specified it is defaulted to ```ROUNDROBIN```
3. Any other options would lead to undefined behaviour
4. To change the number of CPU's we should edit the MakeFile

## Spec 1 : System Calls
Added System calls
### Process of adding systemcalls:
1. Define the function in the syscalls.h and declarations syscalls.c
2. Write the function implementation in the sysproc.c
3. Make the valid changes that were required in the remaining files for the implmentation
4. Changes were made in `proc.h`, `proc.c->fork()`,`proc.c->allocproc()`, `trap.c->usertrap()`.
5. They are nothing but the initializations and updating them.
Added syscalls:
### trace
1. Added `strace.c` in user for testing the syscall.
2. Made required changes in `MAKEFILE` to make this file executable.
### sigalarm and sigreturn
1. Added `alarmtest.c` in user for testing the syscall.
2. Made required changes in `MAKEFILE` to make this file executable.

## Spec 2 : Scheduling
The following are implemented
### FCFS
1. The basic concept is to run the process that is first created
2. We add a new variable to the `struct proc` in `proc.h` (creation time is noted)
3. Initialising the  creationtime to 0 when process is allocated in allocproc
4. The `scheduler()` function is modified by chosing the fucntion with minimum creation time
5. Disabling the preemption (as it is fcfs) in `kerneltrap` and `usertrap` from the `trap.c` file.

### PBS
1. Made a non preemtive method PBS 
2. Added some variables to the struct like sched_time which says number of times it is called,sleep_time , prority , niceness are implemented
3. Made a new scheduling logic for PBS in `scheduler()` which schedules according to the rules of  dynamic priority.
4. The added variables are found by using `update_time` function
5. Made syscall `set_priority` which changes static priority of the process accordingly.
6. The basic logic is to run the process with highest priority

### LBS 
1. Make a premptive method LBS
2. Added a variabe in proccess structure for tickets
3. Made a new scheduling logic for LBS in `scheduler()`
which schedules according to the number of tickets a process has
4. Made syscall `settickets` which changes the number of tickets of the calling process

## SCHEDULER Analysis
We have tested the timings , wait time and run time.
`waitx`  is used provided in the tut.

## Spec 3 : Copy-on-write fork
### Idea :
1. When a parent process creates a child process then both processes initially will share the same pages in memory.
2. These `shared pages will be marked as copy-on-write`.
3. If any of these processes will try to modify the shared pages then copy of these pages will be created 
4. The `modifications will be done on the copy of pages` by that process.
5. Thus not affecting the other process.

### Modifications made :
1. Updated the `uvmuncopy()`, `copyout()` functions in vm.c
2. Declared and implemented the function `page_fault_handler()` in `trap.c`
3. Modified `trapinit()` in `trap.c` with some conditiong on `r_scause()`
4. Declared and implemented the functions `init_page_ref()`, `dec_page_ref()`, `inc_page_ref()` in `kalloc.c`
5. Used the above functions in `kfree()` and `kinit()` in `kalloc.c`

### cow
1. Added `cow.c` in user for testing the syscall.
2. Made required changes in `MAKEFILE` to make this file executable.
