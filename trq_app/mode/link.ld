OUTPUT_ARCH( "riscv" )
ENTRY(main)

SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  .text : { *(.text .text.*) }
  .text.trap : { *(.text.trap) }
  .rodata : { *(.rodata .rodata.*) }
  .data ALIGN(0x1000) : { *(.data .data.*) }
  .bss : { *(.bss .bss.*) }
  _end = .;
}
