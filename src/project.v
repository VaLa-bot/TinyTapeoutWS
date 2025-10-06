`default_nettype none

module tt_um_vga_example(
  input wire [7:0] ui_in,     // Dedizierte Eingänge
  output wire [7:0] uo_out,   // Dedizierte Ausgänge
  input wire [7:0] uio_in,    // IOs: Eingangspfad
  output wire [7:0] uio_out,  // IOs: Ausgangspfad
  output wire [7:0] uio_oe,   // IOs: Enable-Pfad (aktiv High: 0=Eingang, 1=Ausgang)
  input wire ena,             // Immer 1, solange das Design mit Strom versorgt ist
  input wire clk,             // Takt
  input wire rst_n            // Reset_n - Low = Reset
);

  // VGA-Signale
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // VGA-Ausgänge
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Ungenutzte Ausgänge auf 0 gesetzt
  assign uio_out = 0;
  assign uio_oe = 0;

  // Unterdrücken von Warnungen für ungenutzte Signale
  wire _unused_ok = &{ena, uio_in};

  // Instanzierung des hvsync-Generators
  hvsync_generator hvsync_gen (
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // Zähler für langsame Bewegung
  reg [9:0] rect_pos_offset;
  reg [15:0] slow_counter; // Langsamer Zähler, für langsame Bewegung

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      rect_pos_offset <= 0;
      slow_counter <= 0;
    end else begin
      slow_counter <= slow_counter + 1;
      if (slow_counter == 0) begin // Slow down the update of rect_pos_offset
        if (ui_in[0]) begin // Wenn Pin1 high ist
          rect_pos_offset <= rect_pos_offset + 1;
        end
        // Wenn Pin1 niedrig ist, bleibt rect_pos_offset unverändert
      end
    end
  end

  // Definiere die Koordinaten für das Rechteck
  wire inside_rect = (pix_x >= (200 + rect_pos_offset) && pix_x < (440 + rect_pos_offset)) && 
                     (pix_y >= 150 && pix_y < 330);

  // Definiere die Farben
  assign R = video_active && inside_rect ? 2'b11 : 2'b00; // Rot auf Maximum
  assign G = 2'b00; // Kein Grün
  assign B = 2'b00; // Kein Blau

endmodule
