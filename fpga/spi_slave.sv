module spi_slave (
    input  logic clk,           // System clock for internal logic
    input  logic resetn,        // Active-low reset
    input  logic sclk,          // SPI clock
    input  logic mosi,          // Master Out, Slave In
    input  logic ss,            // Active-low Slave Select
    output logic led0,          // LED for the first int16_t (ON if positive, OFF if negative)
    output logic led1,          // LED for the second int16_t (ON if positive, OFF if negative)
    output logic led2           // LED for the third int16_t (ON if positive, OFF if negative)
);

    // Internal registers
    logic [47:0] shift_reg;      // 16-bit shift register to store incoming data
    logic [3:0] bit_counter;     // Counter to track received bits
    logic [1:0] word_counter;    // Counter to track received words (3 words total)

    // SPI slave operation
    always_ff @(posedge sclk) begin
        if (!resetn) begin
            // Reset all registers and LEDs
            shift_reg   <= 16'b0;
         
        end else if (ss) begin
            // Shift in data on MOSI line on each clock edge
            shift_reg <= {shift_reg[46:0], mosi};
            bit_counter <= bit_counter + 1;

       
        end
		
    end
	assign led2= ~shift_reg[14]; 
	assign led1= ~shift_reg[31]; 
    assign led0= ~shift_reg[46]; 
	
endmodule
