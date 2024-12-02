module spi_peripheral (
    input  logic resetn,  // Active-low reset
    input  logic sclk,    // SPI clock
    input  logic sdi,     // Serial Data In (was MOSI)
    input  logic cs_n,    // Active-low Chip Select (was SS)
    output logic led0,    // LED for the first int16_t (ON if positive, OFF if negative)
    output logic led1,    // LED for the second int16_t (ON if positive, OFF if negative)
    output logic led2     // LED for the third int16_t (ON if positive, OFF if negative)
);

  // Internal registers
  logic [47:0] shift_reg;  // 16-bit shift register to store incoming data
  logic [ 3:0] bit_counter;  // Counter to track received bits
  logic [ 1:0] word_counter;  // Counter to track received words (3 words total)

  // SPI peripheral operation
  always_ff @(posedge sclk) begin
    if (!resetn) begin
      // Reset all registers and LEDs
      shift_reg <= 48'b0;

    end else if (cs_n) begin
      // Shift in data on SDI line on each clock edge
      shift_reg   <= {shift_reg[46:0], sdi};
      bit_counter <= bit_counter + 1;
    end

  end

  assign led2 = ~shift_reg[14];
  assign led1 = ~shift_reg[31];
  assign led0 = ~shift_reg[46];

endmodule
