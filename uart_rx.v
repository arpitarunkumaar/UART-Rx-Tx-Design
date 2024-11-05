// UART Rx module - Receives 8 bits of serial data, 1 start bit, 
// 1 stop bit, and 0 parity bits (8-N-1). When Rx is complete, 
// o_data_avail will be driven high for 1 clock cycle.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (clk_freq)/(uart_freq)

module uart_rx
    #(parameter CLKS_PER_BIT = 543)
    (
        input        clk,
        input        i_rx,
        output       o_data_avail,
        output [7:0] o_data_byte
    );
     
    localparam IDLE_STATE    = 2'b00;
    localparam START_STATE   = 2'b01;
    localparam GET_BIT_STATE = 2'b10;
    localparam STOP_STATE    = 2'b11; 
    
    reg rx_buffer = 1'b1;
    reg rx        = 1'b1;
    
    reg [1:0]  state      = 0;
    reg [15:0] counter    = 0;
    reg [2:0]  bit_index  = 0;  // keeps track of next bit
    reg        data_avail = 0;
    reg [7:0]  data_byte  = 0;
    
    assign o_data_avail = data_avail;
    assign o_data_byte  = data_byte; 
    
    // Place double-buffer at incoming Rx line to prevent metastability
    always @(posedge clk) begin 
        rx_buffer <= i_rx;
        rx        <= rx_buffer;
    end
    
    // State Machine
    always @(posedge clk) begin
        case(state)
        
            IDLE_STATE:
                begin 
                    data_avail <= 0;
                    counter    <= 0;
                    bit_index  <= 0;
                    if (rx == 0)    // start condition achieved
                        state <= START_STATE;
                    else
                        state <= IDLE_STATE;
                end
                
            START_STATE:
                begin
                // increment counter until it reaches midpoint of clk, effectively staying in START_STATE
                    if (counter == (CLKS_PER_BIT-1)/2) // wait until middle of start bit
                        begin
                            if (rx == 0)
                                begin
                                    counter <= 0;
                                    state <= GET_BIT_STATE;
                                end
                            else 
                                begin
                                    state <= IDLE_STATE;  // correct error in start bit
                                end
                        end
                    else
                        begin
                            counter <= counter + 16'b1;
                            state   <= START_STATE;
                        end
                end
            
            // Wait CLKS_PER_BIT-1 clk cycles to sample Rx for next bit
            GET_BIT_STATE:
                begin
                    if (counter < CLKS_PER_BIT-1)
                        begin
                            counter <= counter + 16'b1;
                            state   <= GET_BIT_STATE;
                        end
                    else
                        begin // as soon as at midpoint of clk cycle of next bit
                            counter              <= 0;
                            data_byte[bit_index] <= rx; // put sampled rx bit into buffer
                            
                            // verify if all bits received
                            if (bit_index < 7)  // data_byte not full
                                begin
                                    bit_index <= bit_index + 3'b1;
                                    state     <= GET_BIT_STATE;
                                end                            
                            else 
                                begin 
                                    bit_index <= 0;
                                    state     <= STOP_STATE; // transition when all bits received
                                end
                        end
                end
                
            STOP_STATE:
                begin
                    if (counter < CLKS_PER_BIT-1)
                        begin    
                            counter <= counter + 16'b1;
                            state   <= STOP_STATE;
                        end
                    else 
                        begin 
                            data_avail <= 1; // indicating byte fullt recv'd - data on the line is valid
                            counter    <= 0;
                            state      <= IDLE_STATE;
                        end
                end
                    
            default:
                state <= IDLE_STATE;
            
            
        endcase
    end

endmodule
