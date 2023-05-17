+++ 
date = 2019-06-21T23:47:47+05:30
title = "Reverse engineering binaries using gdb"
description = "gdb is a debugger commonly used when programming, but it is also useful for reverse engineering binary code. It lets you step through the assembly code as it runs, and examine the contents of registers and memory"
slug = ""
authors = []
tags = ["gdb", "reverse-engineering", "security"]
categories = []
externalLink = ""
series = []
+++

## General note on compiling for debugging:

Normally, to enable the debugger to use the source code, you would compile a program using the `-g` flag:

```console
$ gcc -g program.c -o program (for lowest level of optimization), or

$ gcc -g -O2 program.c -o program (for optimization level 2)
```

The `-g -O2` combination is valid and enables one to to debug the optimized executable. However the compiler will have generated a lot of optimizations, which will make it more difficult to step through the code. Using -g with no optimizations works best for debugging with source code.

## Examining the executable file

The symbol table is sometimes useful to identify calls to standard library functions, (e.g., `printf`), as well as the bomb's own functions. Note that the symbol table is always present in the executable, even if the executable was compiled without the -g switch.

You can look at all the bomb's symbol table by using `nm`:

```console
$ nm bomb
```

Examine the symbols marked with a T (capital t), and ignore the ones that start with an \_ (underscore). These are names of functions from the C program that was used to compile the bomb.

Next, take a look at the printable strings from the file:

```console
$ strings program 
```

This can often provide clues that will help you understand the program. Then, use `objdump` to disassemble the bomb:

```console
$ objdump -d program | less
```

## GDB (GNU DeBugger) 

gdb is a debugger commonly used when programming, but it is also useful for reverse engineering binary code. It lets you step through the assembly code as it runs, and examine the contents of registers and memory. You can also set breakpoints at arbitrary positions in the program. Breakpoints are points in the code where program execution is instructed to stop. This way, you can let the debugger run without interruption over large portions of code, such as code that we already understand or believe is error-free.

## Starting gdb

Start gdb by specifying what executable to debug:

```console
$ gdb program 
```

You can run the program in the debugger just as you would outside the debugger, except that you can instruct the program to stop at certain locations and inspect current values of memory and registers. As a last resort, you can use (Ctrl-C) to stop the program and panic out. But this is not recommended and is usually not necessary, as long as you positioned our breakpoints appropriately.

To start a program inside gdb:

```console
$ (gdb) run

To start a program inside gdb, with certain input parameters:
$ (gdb) run parameters

Examples:
$ (gdb) run < ./solution.txt
(equivalent to ./program < solution.txt, but inside gdb)

$ (gdb) run -d 1
(equivalent to ./program -d 1)

To exit gdb and return to the shell prompt:
$ (gdb) quit
```

Note that exiting gdb means you lose all of your breakpoints that you set in this gdb session. When you re-run gdb, you need to respecify any breakpoints that you want to re-use.

## Breakpoints

We wouldn't be using gdb if all we did was run the program without any interruptions. We need to stop program execution at certain key positions in the code, and then examine program behavior around those positions. How do we pick a good location for a breakpoint?

First, you can always set a breakpoint at 'main', since every C program has a function called `main`.

```console
$ (gdb) break main
```

You can also set breakpoints at the other functions you identified with `nm`.

To set a breakpoint at the machine instruction located at the address 0x401A23:

```console
(gdb) break *0x401A23
```

Note: don't forget the '0x'. If you forget it, and if you are unlucky enough that the address doesn't contain any A,B,C,D,E,F characters, breakpoint address will be interpreted as if given in the decimal notation. This results in a completely different address to what was desired, and breakpoint won't work as expected.

```console
To see what breakpoints are currently set:
$ (gdb) info break

To delete one or more breakpoints:
$ (gdb) delete <breakpoint number>

Example:
$ (gdb) delete 4 7
erases breakpoints 4 and 7. 
```

## Terminating program execution from within gdb

We can terminate the program at any time:

```console
$ (gdb) kill
```

Note that this doesn't exit gdb, and all your breakpoints remain active. You can re-run the program using the run command, and all breakpoints still apply.

## Stepping through the code

To execute a single machine instruction, use

```console
$ (gdb) stepi
```

Note that if you use `stepi` on a callq instruction, debugger will proceed inside the called function.\
Also note that pressing <ENTER/> re-executes the last gdb command. To execute several `stepi` instructions one after another, type `stepi` once, and then press <ENTER/> several times in a row.

Sometimes we want to execute a single machine instruction, but if that instruction is a call to a function, we want the debugger to execute the function without our intervention. This is achieved using 'nexti':\

```console
$ (gdb) nexti
```

Program will be stopped as soon as control returns from the function, i.e. at the instruction immediately after callq in the caller function.

If you accidentally use stepi to enter a function call, and you really don't want to debug that function, you can use 'finish' to resume execution until the current function returns. Execution will stop at the machine instruction immediately after the 'callq' instruction in the caller function, just as if we had called 'nexti' in the first place:

```console
$ (gdb) finish
```

Note: make sure the current function can really be run safely without your intervention. You don't want it to call explode_bomb.

To instruct the program to execute (without your intervention) until the next breakpoint is hit, use:

```console
$ (gdb) continue
```

The same warning as in the case of 'finish' applies.

If program contains debugging information (i.e., it was compiled with the -g switch to gcc), you can also step a single C statement:

```console
$ (gdb) step
```

Or, if next instruction is a function call, you can use 'next' to execute the function without our intervention. This is just like nexti, except that it operates with C code as opposed to machine instructions:

```console
$ (gdb) next
```

## Disassembling code using gdb

You can use `disassemble` to disassemble a function or a specified address range.

To disassemble function some_function:

```console
$ (gdb) disassemble some_function
```

To disassemble the address range from 0x4005dc to 0x4005eb:

```console
$ (gdb) disassemble 0x4005dc 0x4005eb
```

## Examining registers

To inspect the current values of registers:

```console
(gdb) info registers
```

This prints out the current values of all registers.

To inspect the current values of a specific register (assuming 32-bit registers):

```console
$ (gdb) p $eax

To print the value in hex notation:
$ (gdb) p/x $eax
```

**Note**: if you are debugging a 64-bit program, replace the EXX regirsters with RXX (e.g. use $rax instead of $eax). Using 'p $eax' to print just the lower 32 bits of the register doesn't work (at least with some versions of gdb). You have to print a full 64-bit register.

```console
To see the address of the next machine instruction to be exectued:
$ (gdb) frame
or, equivalently, you can inspect the instruction pointer register:
$ (gdb) p/x $eip

You can also inspect the value of a variable:
$ (gdb) p buffer

or its address:
$ (gdb) p &buffer
```

When debugging a C/C++ program for which the source code is available, you can also inspect the call-stack (a list of all nested function calls that led to the current function being executed):\

```console
$ (gdb) where
```

## Examining memory

To inspect the value of memory at location 0x400746:

```console
$ (gdb) x/NFU 0x400746
```

Here:

- N = number of units to display
- F = output format (hex=h, signed decimal=d, unsigned decimal=u, string=s, char=c)
- U = defines what constitutes a unit: b=1 byte, h=2 bytes, w=4 bytes, g=8 bytes

Note that output format and unit definition characters are mutually distinct from each other.

Examples:

```console
To use hex notation, and print two consecutive 64-bit words, starting from the address 0x400746 and higher:
$ (gdb) x/2xg 0x400746

To print a null-terminated string at location 0x400746:
$ (gdb) x/s 0x400746

To use hex notation, and print five consecutive 32-bit words, starting from the address 0x400746:
$ (gdb) x/5xw 0x400746

To print a single 32-bit word, in decimal notation, at the address 0x400746:
$ (gdb) x/1dw 0x400746
```

## Examining core files

If your program segfaults, it is sometimes useful to examine the core dump (for example, memory addresses may be different when running a program in gdb and when executing it separately). To do this, you first have to configure your operating system to dump core:

```console
$ uname -c unlimited
```

When a program receives a segmentation fault (SEGFAULT) signal, you will find a corefile (typically called core or core.PID, where PID is the ID of the process that crashed) in the current directory. Load it in gdb as follows:

```console
$ (gdb) core corefile
```

You can then use all the gdb commands described above to examine the state of the stack, variables, memory, etc. when the process crashed.

## GDB references

- [Quick reference card](https://www.cs.umd.edu/class/spring2015/cmsc414/downloads/gdb-refcard.pdf)
- [The full manual](http://www.gnu.org/software/gdb/documentation/)

</div>
