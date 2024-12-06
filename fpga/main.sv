module main (
    // LED Matrix outputs
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
    LAT,

    // SPI interface
    input  logic sdi,
    sclk,
    cs_n,
    resetn,
    output logic led0,
    led1,
    led2
);
  logic int_osc;
  oscillator oscillator (.clk(int_osc));

  // Memory write interface signals
  logic write_en;
  logic [5:0] write_x, write_y;
  logic [11:0] pixel_color;

  //   // Pattern generator instance
  //   physics_engine pattern_gen (
  //       .clk(int_osc),
  //       .resetn(resetn),
  //       .write_en(write_en),
  //       .write_x(write_x),
  //       .write_y(write_y),
  //       .pixel_color(pixel_color),
  //       .led0(led0),
  //       .led1(led1),
  //       .led2(led2)
  //   );

  // Create internal signals for LED states from SPI
  logic led0_int, led1_int, led2_int;

  // Direction control from SPI
  logic [2:0] direction;

  assign direction = {led2_int, led1_int, led0_int};  // Connect LED outputs to direction control

  // Pattern generator instance
  pattern_generator pattern_gen (
      .clk(int_osc),
      .resetn(resetn),
      .direction(direction),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .pixel_color(pixel_color)
  );

  // SPI peripheral instance
  spi_peripheral spi (
      .resetn(resetn),
      .sclk(sclk),
      .sdi(sdi),
      .cs_n(cs_n),
      .led0(led0_int),
      .led1(led1_int),
      .led2(led2_int)
  );

  // LED matrix display instance
  display led_matrix (
      .clk_in(int_osc),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(pixel_color),
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
  assign led0 = led0_int;
  assign led1 = led1_int;
  assign led2 = led2_int;

endmodule
