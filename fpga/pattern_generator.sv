module pattern_generator (
    input logic clk,
    input logic resetn,
    input logic [2:0] direction,
    output logic write_en,
    output logic [5:0] write_x,
    output logic [5:0] write_y,
    output logic [11:0] pixel_color
);

  // Constants for number of particles
  localparam NUM_PARTICLES = 10;

  // Arrays to track multiple particles
  logic [5:0] sand_x[NUM_PARTICLES-1:0];
  logic [5:0] sand_y[NUM_PARTICLES-1:0];
  logic [19:0] update_counter;

  // Border detection for current pixel being drawn
  logic is_border;
  assign is_border = (write_x == 6'd63) || (write_x == 6'd0) || (write_y == 6'd63) || (write_y == 6'd0);

  // Initial positions for particles
  logic [5:0] initial_positions[NUM_PARTICLES-1:0];
  assign initial_positions = '{
          6'd27,
          6'd28,
          6'd29,
          6'd30,
          6'd31,
          6'd32,
          6'd33,
          6'd34,
          6'd35,
          6'd36
      };

  // Direction logic - corrected directions
  logic signed [6:0] dir_x;  // 7 bits to handle signed arithmetic
  logic signed [6:0] dir_y;

  always_comb begin
    case (direction)
      3'b000:  {dir_x, dir_y} = {7'sd0, 7'sd1};  // South
      3'b001:  {dir_x, dir_y} = {-7'sd1, 7'sd1};  // Southeast (flipped dir_x)
      3'b010:  {dir_x, dir_y} = {-7'sd1, 7'sd0};  // East (flipped dir_x)
      3'b011:  {dir_x, dir_y} = {-7'sd1, -7'sd1};  // Northeast (flipped dir_x)
      3'b100:  {dir_x, dir_y} = {7'sd0, -7'sd1};  // North
      3'b101:  {dir_x, dir_y} = {7'sd1, -7'sd1};  // Northwest (flipped dir_x)
      3'b110:  {dir_x, dir_y} = {7'sd1, 7'sd0};  // West (flipped dir_x)
      3'b111:  {dir_x, dir_y} = {7'sd1, 7'sd1};  // Southwest (flipped dir_x)
      default: {dir_x, dir_y} = {7'sd0, 7'sd1};  // Default South
    endcase
  end

  // Particle motion update logic with collision detection
  always_ff @(posedge clk or negedge resetn) begin
    // Variable declarations must be at the top of the procedural block
    logic signed [6:0] next_x[NUM_PARTICLES-1:0];
    logic signed [6:0] next_y[NUM_PARTICLES-1:0];
    logic can_move[NUM_PARTICLES-1:0];

    if (!resetn) begin
      update_counter <= 20'd0;
      for (int i = 0; i < NUM_PARTICLES; i++) begin
        sand_x[i] <= initial_positions[i];
        sand_y[i] <= 6'd31;
      end
    end else begin
      update_counter <= update_counter + 20'd1;
      if (update_counter == 20'd262143) begin
        // Update particles periodically
        update_counter <= 20'd0;

        // Compute candidate next positions
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          next_x[i]   = sand_x[i] + dir_x;
          next_y[i]   = sand_y[i] + dir_y;
          can_move[i] = 1'b1;  // Initialize can_move flag
        end

        // Collision detection
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          // Check bounds first
          if (next_x[i] <= 7'sd0 || next_x[i] >= 7'sd63 || next_y[i] <= 7'sd0 || next_y[i] >= 7'sd63) begin
            can_move[i] = 1'b0;  // Cannot move out of bounds
          end else begin
            // Check collisions with other particles
            for (int j = 0; j < NUM_PARTICLES; j++) begin
              if (i != j) begin
                // Check if next position collides with other's current position
                if (next_x[i] == sand_x[j] && next_y[i] == sand_y[j]) begin
                  can_move[i] = 1'b0;  // Cannot move into a space occupied by another particle
                end  // Check if next position collides with other's next position
                else if (next_x[i] == next_x[j] && next_y[i] == next_y[j]) begin
                  // Particles attempting to move to the same position
                  // To avoid conflict, only allow the particle with the lower index to move
                  if (i > j) begin
                    can_move[i] = 1'b0;  // Stop this particle from moving
                  end
                end
              end
            end
          end
        end

        // Update positions based on can_move flags
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          if (can_move[i]) begin
            sand_x[i] <= next_x[i][5:0];
            sand_y[i] <= next_y[i][5:0];
          end
          // Else, keep current position
        end
      end
    end
  end

  // Scan and write logic
  logic [5:0] scan_x;
  logic [5:0] scan_y;
  logic [3:0] write_divider;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      scan_x <= 6'd0;
      scan_y <= 6'd0;
      write_divider <= 4'd0;
      write_en <= 1'b0;
    end else begin
      write_divider <= write_divider + 4'd1;
      if (write_divider == 4'd0) begin
        write_en <= 1'b1;
        write_x  <= scan_x;
        write_y  <= scan_y;
        // Increment scan coordinates
        if (scan_x == 6'd63) begin
          scan_x <= 6'd0;
          scan_y <= (scan_y == 6'd63) ? 6'd0 : scan_y + 6'd1;
        end else begin
          scan_x <= scan_x + 6'd1;
        end
      end else begin
        write_en <= 1'b0;
      end
    end
  end

  // Check if the current pixel is a sand particle
  logic is_sand;
  always_comb begin
    is_sand = 1'b0;
    for (int i = 0; i < NUM_PARTICLES; i++) begin
      if (write_x == sand_x[i] && write_y == sand_y[i]) begin
        is_sand = 1'b1;
        break;  // Exit loop early if found
      end
    end
  end

  // Pixel color assignment
  always_comb begin
    if (is_border) begin
      pixel_color = 12'hFFF;  // Border color (white)
    end else if (is_sand) begin
      pixel_color = 12'hFF0;  // Sand color (yellow)
    end else begin
      pixel_color = 12'h000;  // Background color (black)
    end
  end

endmodule
