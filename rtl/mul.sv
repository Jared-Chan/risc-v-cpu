//`define TRACE $display(" BEFORE start_synchronizer=0x%8h start_sync=0x%8h mul1_sync=0x%8h mul2_sync=0x%8h ready_synchronizer=0x%8h ready_sync=0x%8h result_h=0x%8h result_l=0x%8h ready_ack=0x%8h ready_ack_synchronizer=0x%8h ready_ack_sync=0x%8h state=0x%8h ready=0x%8h result=0x%h count=0x%8h mul1_u=0x%8h mul2_u=0x%8h result[Width*2-1:Width-1]=0x%h", start_synchronizer, start_sync, mul1_sync, mul2_sync, ready_synchronizer, ready_sync, result_h, result_l, ready_ack, ready_ack_synchronizer, ready_ack_sync, state, ready, result, count, mul1_u, mul2_u, result[Width*2-1:Width-1],); $strobe(" AFTER start_synchronizer=0x%8h start_sync=0x%8h mul1_sync=0x%8h mul2_sync=0x%8h ready_synchronizer=0x%8h ready_sync=0x%8h result_h=0x%8h result_l=0x%8h ready_ack=0x%8h ready_ack_synchronizer=0x%8h ready_ack_sync=0x%8h state=0x%8h ready=0x%8h result=0x%h count=0x%8h mul1_u=0x%8h mul2_u=0x%8h result[Width*2-1:Width-1]=0x%h", start_synchronizer, start_sync, mul1_sync, mul2_sync, ready_synchronizer, ready_sync, result_h, result_l, ready_ack, ready_ack_synchronizer, ready_ack_sync, state, ready, result, count, mul1_u, mul2_u, result[Width*2-1:Width-1],);

module mul #(
    parameter byte Width = 32
) (
    input logic rst_n,
    input logic clk_sys,
    input logic [Width-1:0] multiplicand,
    input logic [Width-1:0] multiplier,
    input logic start,
    input logic multiplicand_signed,
    input logic multiplier_signed,

    input logic clk_mul,
    output logic ready_sync,
    output logic [Width-1:0] result_l,
    output logic [Width-1:0] result_h
);

  /* slow-to-fast synchronization */
  logic [1:0] start_synchronizer;
  always_ff @(posedge clk_mul, negedge rst_n) begin
    if (!rst_n) start_synchronizer <= '0;
    else start_synchronizer <= {start_synchronizer[0], start};
  end

  always_ff @(posedge clk_mul, negedge rst_n) begin
    if (!rst_n) start_sync <= '0;
    else if (start_synchronizer[1]) begin
      start_sync <= '1;
      mul1_sync <= multiplicand;
      mul2_sync <= multiplier;
      mul1_signed_sync <= multiplicand_signed;
      mul2_signed_sync <= multiplier_signed;
    end else begin
      start_sync <= '0;
    end
  end
  /* end slow-to-fast synchronization */

  /* fast-to-slow synchronization */
  logic [1:0] ready_synchronizer;
  always_ff @(posedge clk_sys, negedge rst_n) begin
    if (!rst_n) ready_synchronizer <= '0;
    else ready_synchronizer <= {ready_synchronizer[0], ready};
  end

  always_ff @(posedge clk_sys, negedge rst_n) begin
    if (!rst_n) ready_sync <= '0;
    else if (ready_synchronizer[1]) begin
      ready_sync <= '1;
      result_h  <= result[(Width*2)-1:Width];
      result_l  <= result[Width-1:0];
      ready_ack  <= '1;
    end else begin
      ready_sync <= '0;
      ready_ack  <= '0;
    end
  end

  // acknowledgement
  logic [1:0] ready_ack_synchronizer;
  logic ready_ack;
  always_ff @(posedge clk_mul, negedge rst_n) begin
    if (!rst_n) ready_ack_synchronizer <= '0;
    else ready_ack_synchronizer <= {ready_ack_synchronizer[0], ready_ack};
  end

  always_ff @(posedge clk_mul, negedge rst_n) begin
    if (!rst_n) ready_ack_sync <= '0;
    else if (ready_ack_synchronizer[1]) begin
      ready_ack_sync <= '1;
    end else begin
      ready_ack_sync <= '0;
    end
  end
  /* end fast-to-slow synchronization */

  /* Multiplier */

  typedef enum {
    IDLE,
    MULTIPLY,
    COMPLEMENT,
    WAIT_ACK
  } mul_state_e;

  mul_state_e state, next;
  logic start_sync;
  logic mul1_signed_sync, mul2_signed_sync;
  logic [Width-1:0] mul1_sync;
  logic [Width-1:0] mul2_sync;
  logic [Width-1:0] mul1_u;
  logic [Width-1:0] mul2_u;
  logic [(Width*2)-1:0] result;
  logic [Width:0] partial_result;
  logic [7:0] count;
  logic ready;
  logic ready_ack_sync;

  always_ff @(posedge clk_mul, negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else state <= next;
  end

  always_comb begin
    case (state)
      IDLE: begin
        if (start_sync) next = MULTIPLY;
        else next = IDLE;
      end
      MULTIPLY: begin
        if (count == Width - 1) begin
          if (mul1_signed_sync && mul2_signed_sync &&
              (mul1_sync[Width-1] ^ mul2_sync[Width-1])) begin
            next = COMPLEMENT;
          end else if (mul2_signed_sync && ~mul1_signed_sync && mul2_sync[Width-1]) begin
            next = COMPLEMENT;
          end else if (mul1_signed_sync && ~mul2_signed_sync && mul1_sync[Width-1]) begin
            next = COMPLEMENT;
          end else next = WAIT_ACK;
        end else begin
          next = MULTIPLY;
        end
      end
      COMPLEMENT: begin
        next = WAIT_ACK;
      end
      WAIT_ACK: begin
        if (ready_ack_sync) next = IDLE;
        else next = WAIT_ACK;
      end
      default: ;
    endcase
  end

  always_comb begin
    // 32-bit addition (+ carry) to the upper bits of result
    if (mul1_u[0]) begin
      partial_result = {1'b0, result[(Width*2)-1:Width]} + {1'b0, mul2_u};
    end else partial_result = {1'b0, result[(Width*2)-1:Width]};
  end

  always_ff @(posedge clk_mul, negedge rst_n) begin
    if (!rst_n) begin
      ready  <= '0;
      result <= '0;
    end else begin
          //`TRACE
      case (state)
        IDLE: begin
          ready <= '1;
          if (start_sync) begin
            ready <= '0;
            count <= '0;
            result <= '0;
            // Unsigned operands
            mul1_u <= (mul1_signed_sync && mul1_sync[Width-1] == 1'b1) ? ~mul1_sync + 1 : mul1_sync;
            mul2_u <= (mul2_signed_sync && mul2_sync[Width-1] == 1'b1) ? ~mul2_sync + 1 : mul2_sync;
          end
        end
        MULTIPLY: begin
          // shift result to the right
          result <= {1'b0, partial_result, result[Width-1:1]};
          // shift mul1_u to the right
          mul1_u <= mul1_u >> 1'b1;

          count  <= count + 1'b1;
        end
        COMPLEMENT: begin
          result <= ~result + 1'b1;
        end
        WAIT_ACK: begin
          ready <= '1;
        end
        default: ;
      endcase
    end
  end
  /* End Multiplier */

endmodule
