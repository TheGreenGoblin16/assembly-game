@echo off

tasm\bin\tasm.exe %1%.asm
tasm\bin\tlink.exe %1%.obj

del %1%.obj
del %1%.MAP