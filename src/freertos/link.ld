OUTPUT_ARCH( "riscv" )

MEMORY
{
    ram (wx) : ORIGIN = 0, LENGTH = 64K
}

SECTIONS
{
  . = 0x00000000;
  .text : { 
      KEEP(*(.text._boot))
      *(.text)
  } > ram
  .data : { *(.data) } > ram
  .bss : { 
      __bss_start = .;
    *(.bss*)
  } > ram

  .stack :
  {
    . = ALIGN(16);
    . = ORIGIN(ram) + LENGTH(ram);
    /*. += 4K;*/
    _stack_top = .;
  } > ram
  PROVIDE ( _stack = _stack_top );
  PROVIDE ( __freertos_irq_stack_top = _stack_top );


  _end = .;

}

