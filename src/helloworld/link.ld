OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    ram (wx) : ORIGIN = 0, LENGTH = 4K
}

SECTIONS
{
  . = 0x00000000;
  .text : { 
      KEEP(*(.text._start))
      *(.text)
  } > ram
  .data : { *(.data) } > ram
  .bss : { *(.bss) } > ram
  _end = .;

  PROVIDE ( _stack = ORIGIN(ram) + LENGTH(ram) );
}


