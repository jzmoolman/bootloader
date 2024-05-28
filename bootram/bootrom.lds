OUTPUT_ARCH( "riscv" )

ENTRY( _entry )

SECTIONS
{
  . = 0x1000;
  PROVIDE(reset_vector = . );
  
  .text :
  {
    PROVIDE( _entry = . );
    *(.reset)
    *(*)
  }
  . = ALIGN(4);

  PROVIDE( _dtb = . );
}
