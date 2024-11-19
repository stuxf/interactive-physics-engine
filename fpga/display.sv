module display (
    input logic clk_in,

    // Memory Interface
    input logic write_en,
    input logic [5:0] write_x,
    input logic [5:0] write_y,
    input logic [2:0] write_color,

    // Row Select
    output logic A,
    B,
    C,
    D,
    E,
    // Top Half Colors
    output logic R1,
    B1,
    G1,
    // Bottom Half Colors
    output logic R2,
    B2,
    G2,
    // Control Signals
    output logic CLK,
    output logic OE,
    output logic LAT
);

  // State and counters
  typedef enum logic [1:0] {
    SHIFT   = 2'b00,
    LATCH   = 2'b01,
    DISPLAY = 2'b10
  } state_t;

  state_t state, nextstate;
  logic [5:0] col_count;
  logic [4:0] row_count;
  logic [7:0] display_timer;

  // Clock divider for slower operation (2**3)
  logic [2:0] clk_div;
  logic pixel_clk;

  always_ff @(posedge clk_in) begin
    clk_div <= clk_div + 1;
  end

  // Divide clock by 8
  assign pixel_clk = clk_div[2];

  // Row address assignment
  assign {E, D, C, B, A} = row_count;  // Binary to row select pins

  // Instantiate pixel memory
  pixel_memory pixel_mem (
      .clk(clk_in),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(write_color),
      .col_addr(col_count),
      .row_addr(row_count),
      .R1(R1),
      .G1(G1),
      .B1(B1),
      .R2(R2),
      .G2(G2),
      .B2(B2)
  );

  // State and control registers
  always_ff @(posedge pixel_clk) begin
    state <= nextstate;

    case (state)
      SHIFT: begin
        CLK <= ~CLK;  // Toggle clock in registered logic
        if (CLK) begin  // On current clock high
          if (col_count == 63) col_count <= '0;
          else col_count <= col_count + 1;
        end
      end

      LATCH: begin
        CLK <= 1'b0;
        display_timer <= '0;
      end

      DISPLAY: begin
        CLK <= 1'b0;
        if (display_timer == 255) begin
          if (row_count == 31) row_count <= '0;
          else row_count <= row_count + 1;
        end else begin
          display_timer <= display_timer + 1;
        end
      end

      default: begin
        CLK <= 1'b0;
      end
    endcase
  end

  // Next state logic
  always_comb begin
    unique case (state)
      SHIFT: begin
        if (CLK && col_count == 63) nextstate = LATCH;
        else nextstate = SHIFT;
      end

      LATCH: nextstate = DISPLAY;

      DISPLAY: begin
        if (display_timer == 255) nextstate = SHIFT;
        else nextstate = DISPLAY;
      end

      default: nextstate = SHIFT;
    endcase
  end

  // Output logic (pure combinational outputs)
  always_comb begin
    unique case (state)
      SHIFT: begin
        OE  = 1'b1;  // Disable while shifting
        LAT = 1'b0;
      end

      LATCH: begin
        OE  = 1'b1;
        LAT = 1'b1;
      end

      DISPLAY: begin
        OE  = 1'b0;  // Enable output
        LAT = 1'b0;
      end

      default: begin
        OE  = 1'b1;
        LAT = 1'b0;
      end
    endcase
  end

endmodule
