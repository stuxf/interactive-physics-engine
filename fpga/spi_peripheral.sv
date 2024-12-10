/*
 * Amy Liu
 * December 1st, 2024
 * amyliu01@g.hmc.edu
 * Takes SPI input from IMU and outputs results to LEDS
 */
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
  logic [15:0] shift_reg;  // 16-bit shift register to store incoming data
  logic [ 3:0] bit_counter;  // Counter to track received bits

  // SPI peripheral operation
  always_ff @(posedge sclk) begin
    if (!resetn) begin
      // Reset all registers and LEDs
      shift_reg   <= 16'b0;
      bit_counter <= 4'b0;
    end else if (cs_n) begin  // Restored original cs_n logic
      // Shift in data on SDI line on each clock edge
      shift_reg   <= {shift_reg[14:0], sdi};
      bit_counter <= bit_counter + 1;
    end
  end

  // Angle segment decoder
  logic [8:0] segment;  // Which 45-degree segment (0-7)

  // Convert 16-bit angle to 45-degree segment
  // Using a combinational block for clarity
  always_comb begin
    segment = shift_reg[15:0] / 16'd45;  // Integer division by 45

    // Default all LEDs off (0-44 degrees)
    {led2, led1, led0} = 3'b000;

    case (segment)
      0: {led2, led1, led0} = 3'b000;  //   0-44
      1: {led2, led1, led0} = 3'b001;  //  45-89
      2: {led2, led1, led0} = 3'b010;  //  90-134
      3: {led2, led1, led0} = 3'b011;  // 135-179
      4: {led2, led1, led0} = 3'b100;  // 180-224
      5: {led2, led1, led0} = 3'b101;  // 225-269
      6: {led2, led1, led0} = 3'b110;  // 270-314
      7: {led2, led1, led0} = 3'b111;  // 315-359
      default: {led2, led1, led0} = 3'b000;
    endcase
  end

endmodule
