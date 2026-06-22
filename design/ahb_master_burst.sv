import ahb_pkg::*;

module ahb_master_burst (
    ahb_if.Master m_bus,
    input  logic                      start_burst,
    input  logic [AHB_ADDR_WIDTH-1:0] start_addr,
    input  logic                      write_mode,
    input  logic [AHB_DATA_WIDTH-1:0] data_stream [4]
);

    typedef enum logic [2:0] {
        M_IDLE, M_NONSEQ, M_SEQ1, M_SEQ2, M_SEQ3, M_DRAIN
    } m_state_e;

    m_state_e state, next_state, state_q; // state_q tracks the DATA PHASE
    logic [AHB_ADDR_WIDTH-1:0] addr_reg;

    // 1. FSM & Address Phase Logic
 always_ff @(posedge m_bus.clk or negedge m_bus.rst_n) begin
        if (!m_bus.rst_n) begin
            state    <= M_IDLE;
            state_q  <= M_IDLE; 
            addr_reg <= '0;
            m_bus.hburst <= HBURST_SINGLE; 
        end else if (m_bus.hready) begin
            state    <= next_state;
            state_q  <= state; 
            
            if (state == M_IDLE && start_burst) begin
                addr_reg     <= start_addr;
                m_bus.hburst <= HBURST_INCR4; 
            end else if (state == M_NONSEQ || state == M_SEQ1 || state == M_SEQ2) begin
                addr_reg     <= addr_reg + 4;
            end else if (next_state == M_IDLE) begin
                m_bus.hburst <= HBURST_SINGLE; // Return to single transfer mode when done
            end
        end
    end

    // 2. Next State Logic
    always_comb begin
        next_state = state;
        case (state)
            M_IDLE:   if (start_burst) next_state = M_NONSEQ;
            M_NONSEQ: next_state = M_SEQ1;
            M_SEQ1:   next_state = M_SEQ2;
            M_SEQ2:   next_state = M_SEQ3;
            M_SEQ3:   next_state = M_DRAIN;
            M_DRAIN:  next_state = M_IDLE;
            default:  next_state = M_IDLE;
        endcase
    end

    // 3. Address Phase Outputs (Uses current state)
    always_comb begin
        m_bus.hwrite = write_mode;
        m_bus.haddr  = addr_reg;
        case (state)
            M_IDLE:   m_bus.htrans = HTRANS_IDLE;
            M_NONSEQ: m_bus.htrans = HTRANS_NONSEQ;
            M_SEQ1, M_SEQ2, M_SEQ3: m_bus.htrans = HTRANS_SEQ;
            default:  m_bus.htrans = HTRANS_IDLE;
        endcase
    end

    // 4. Data Phase Outputs (Uses state_q to lag by 1 cycle)
    always_comb begin
        case (state_q)
            M_NONSEQ: m_bus.hwdata = data_stream[0];
            M_SEQ1:   m_bus.hwdata = data_stream[1];
            M_SEQ2:   m_bus.hwdata = data_stream[2];
            M_SEQ3:   m_bus.hwdata = data_stream[3];
            default:  m_bus.hwdata = '0;
        endcase
    end

endmodule
