OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  .text : { *(.text .text.*) }
  .rodata : { *(.rodata .rodata.*) }
  .data ALIGN(0x1000) : { *(.data .data.*) }
  .bss : { 
    __bss_start = .;
    *(.bss .bss.*)
    __bss_end = .;
  }
  _end = .;
}
