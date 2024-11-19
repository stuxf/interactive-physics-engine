module main (
    // input logic SDI, SDO, SCLK, CE,
    output logic A,
    B,
    C,
    D,
    E,
    output logic R1,
    R2,
    B1,
    B2,
    G1,
    G2,
    output logic CLK,
    OE,
    LAT
);
  logic int_osc;
  oscillator oscillator (.clk(int_osc));

  display led_matrix (
      .clk_in(int_osc),
      .A(A),
      .B(B),
      .C(C),
      .D(D),
      .E(E),
      .R1(R1),
      .B1(B1),
      .G1(G1),
      .R2(R2),
      .B2(B2),
      .G2(G2),
      .CLK(CLK),
      .OE(OE),
      .LAT(LAT)
  );

endmodule
