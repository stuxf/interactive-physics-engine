module oscillator (
    output clk
);

  // Internal Clock
  SB_HFOSC #(
      .CLKHF_DIV("0b10")
  ) OSCInst1 (
      // Enable low speed clock output
      .CLKHFEN(1'b1),
      // Power up the oscillator
      .CLKHFPU(1'b1),
      // Oscillator Clock Output
      .CLKHF  (clk)
  );

endmodule
