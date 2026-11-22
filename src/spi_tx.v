`timescale 1ns / 1ps
//==============================================================================
// Файл    : spi_tx.v
// Модуль  : spi_tx - передавач SPI Master (режим 0: CPOL = 0, CPHA = 0)
//
// Призначення:
//   Приймає паралельне слово tx_data, формує сигнали CS_N та SCK і послідовно
//   (старшим бітом вперед, MSB first) виставляє біти на лінію MOSI.
//   Також видає 1-тактовий імпульс sck_rise щоразу, коли SCK переходить 0 -> 1.
//   За цим імпульсом приймач (spi_rx) читає лінію MISO.
//
// Режим 0 (CPOL = 0, CPHA = 0):
//   - у стані спокою SCK = 0;
//   - дані змінюються по ЗРІЗУ SCK (1 -> 0), перший біт виставляється одразу
//     після опускання CS_N;
//   - дані фіксуються (зчитуються) по ФРОНТУ SCK (0 -> 1).
//
// Частота SCK:  f_sck = f_clk / (2 * CLK_DIV).
// Приклад: f_clk = 100 МГц, CLK_DIV = 4  ->  f_sck = 12.5 МГц.
//
// FSM передавача (5 станів):
//   S_IDLE  - очікування start; CS_N = 1, SCK = 0;
//   S_START - CS_N опущено, пауза півперіоду (час від CS до першого фронту);
//   S_HIGH  - SCK = 1 (півперіод), по завершенні SCK -> 0 і виставляється наступний біт;
//   S_LOW   - SCK = 0 (півперіод), по завершенні SCK -> 1;
//   S_STOP  - після останнього біта пауза півперіоду, потім CS_N = 1, імпульс done.
//==============================================================================
module spi_tx #(
    parameter DATA_WIDTH = 8,   // розрядність слова
    parameter CLK_DIV    = 4    // тактів clk у півперіоді SCK (мінімум 2, рекомендовано 4)
) (
    input  wire                  clk,       // системний тактовий сигнал
    input  wire                  rst,       // синхронне скидання, активний рівень 1
    input  wire                  start,     // імпульс запуску передачі (1 такт)
    input  wire [DATA_WIDTH-1:0] tx_data,   // слово для передачі
    output reg                   sck,       // тактовий сигнал SPI
    output reg                   mosi,      // дані Master -> Slave
    output reg                   cs_n,      // вибір Slave, активний рівень 0
    output reg                   busy,      // 1 - триває передача
    output reg                   done,      // імпульс (1 такт) - передачу завершено
    output reg                   sck_rise   // імпульс (1 такт) - SCK щойно став 1
);

    // Розрядність лічильника дільника частоти
    localparam DIV_W = (CLK_DIV > 1) ? $clog2(CLK_DIV) : 1;

    // Кодування станів FSM
    localparam [2:0] S_IDLE  = 3'd0,
                     S_START = 3'd1,
                     S_HIGH  = 3'd2,
                     S_LOW   = 3'd3,
                     S_STOP  = 3'd4;

    reg [2:0]            state;      // поточний стан FSM
    reg [DATA_WIDTH-1:0] shift_reg;  // зсувний регістр з даними для передачі
    reg [4:0]            bit_cnt;    // кількість уже переданих бітів
    reg [DIV_W-1:0]      div_cnt;    // лічильник дільника частоти (півперіод SCK)

    // tick = 1, коли минув півперіод SCK (CLK_DIV тактів clk)
    wire tick = (div_cnt == CLK_DIV - 1);

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            sck       <= 1'b0;
            mosi      <= 1'b0;
            cs_n      <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
            sck_rise  <= 1'b0;
            shift_reg <= {DATA_WIDTH{1'b0}};
            bit_cnt   <= 5'd0;
            div_cnt   <= {DIV_W{1'b0}};
        end else begin
            // Імпульсні сигнали за замовчуванням неактивні
            done     <= 1'b0;
            sck_rise <= 1'b0;

            case (state)
                //------------------------------------------------------------
                S_IDLE: begin
                    sck     <= 1'b0;
                    cs_n    <= 1'b1;
                    div_cnt <= {DIV_W{1'b0}};
                    bit_cnt <= 5'd0;
                    if (start) begin
                        shift_reg <= tx_data;                 // завантажити слово
                        mosi      <= tx_data[DATA_WIDTH-1];   // виставити старший біт
                        cs_n      <= 1'b0;                    // вибрати Slave
                        busy      <= 1'b1;
                        state     <= S_START;
                    end
                end
                //------------------------------------------------------------
                S_START: begin
                    if (tick) begin
                        div_cnt  <= {DIV_W{1'b0}};
                        sck      <= 1'b1;        // перший фронт SCK
                        sck_rise <= 1'b1;
                        state    <= S_HIGH;
                    end else
                        div_cnt <= div_cnt + 1'b1;
                end
                //------------------------------------------------------------
                S_HIGH: begin
                    if (tick) begin
                        div_cnt <= {DIV_W{1'b0}};
                        sck     <= 1'b0;         // зріз SCK
                        bit_cnt <= bit_cnt + 1'b1;
                        if (bit_cnt == DATA_WIDTH - 1) begin
                            state <= S_STOP;     // це був останній біт
                        end else begin
                            // зсунути регістр і виставити наступний біт на MOSI
                            shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                            mosi      <= shift_reg[DATA_WIDTH-2];
                            state     <= S_LOW;
                        end
                    end else
                        div_cnt <= div_cnt + 1'b1;
                end
                //------------------------------------------------------------
                S_LOW: begin
                    if (tick) begin
                        div_cnt  <= {DIV_W{1'b0}};
                        sck      <= 1'b1;        // наступний фронт SCK
                        sck_rise <= 1'b1;
                        state    <= S_HIGH;
                    end else
                        div_cnt <= div_cnt + 1'b1;
                end
                //------------------------------------------------------------
                S_STOP: begin
                    if (tick) begin
                        div_cnt <= {DIV_W{1'b0}};
                        cs_n    <= 1'b1;         // зняти вибір Slave
                        busy    <= 1'b0;
                        done    <= 1'b1;         // передачу завершено
                        state   <= S_IDLE;
                    end else
                        div_cnt <= div_cnt + 1'b1;
                end
                //------------------------------------------------------------
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
