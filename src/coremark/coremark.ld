OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    ram (wx) : ORIGIN = 0, LENGTH = 32K
}

SECTIONS
{
  . = 0x00000000;
  .text : { 
      KEEP(*(.text._boot))
      *(.text)
  } > ram
  .sdata : { 
      PROVIDE (__global_pointer$ = . + 0x800);
      *(.sdata)
  } > ram
  .data : { *(.data) } > ram
  .bss : { 
      __bss_start = .;
    *(.bss*)
  } > ram
  _end = .;

  PROVIDE ( _stack = ORIGIN(ram) + LENGTH(ram) );
}


