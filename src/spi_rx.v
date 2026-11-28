`timescale 1ns / 1ps
//==============================================================================
// Файл    : spi_rx.v
// Модуль  : spi_rx - приймач SPI Master (режим 0)
//
// Призначення:
//   Збирає слово з лінії MISO. Кожного разу, коли передавач повідомляє імпульсом
//   sample (= sck_rise), що SCK щойно став 1, приймач читає один біт MISO і
//   зсуває його в регістр (MSB first). Після DATA_WIDTH бітів слово
//   записується в rx_data і видається 1-тактовий імпульс rx_valid.
//
// Лінія MISO приходить асинхронно відносно clk, тому проходить через
// дворівневий синхронізатор (miso_sync) для захисту від метастабільності.
// Через це слід брати CLK_DIV >= 2 (рекомендовано 4).
//
// Логіка приймача (FSM неявно, через лічильник бітів):
//   idle (cs_n = 1)  -> лічильник бітів скинуто, приймач чекає початку обміну;
//   receive          -> по кожному sample зсув біта в shift_reg, bit_cnt + 1;
//   ready            -> після DATA_WIDTH бітів: rx_data <= слово, rx_valid = 1.
//==============================================================================
module spi_rx #(
    parameter DATA_WIDTH = 8
) (
    input  wire                  clk,       // системний тактовий сигнал
    input  wire                  rst,       // синхронне скидання, активний рівень 1
    input  wire                  sample,    // імпульс: зчитати біт MISO (sck_rise)
    input  wire                  cs_n,      // вибір Slave (1 - обмін не триває)
    input  wire                  miso,      // дані Slave -> Master
    output reg  [DATA_WIDTH-1:0] rx_data,   // прийняте слово (зберігається до наступного)
    output reg                   rx_valid   // імпульс (1 такт): rx_data дійсне
);

    reg [DATA_WIDTH-1:0] shift_reg;   // зсувний регістр прийому
    reg [4:0]            bit_cnt;     // кількість прийнятих бітів
    reg [1:0]            miso_sync;   // синхронізатор лінії MISO

    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= {DATA_WIDTH{1'b0}};
            rx_data   <= {DATA_WIDTH{1'b0}};
            rx_valid  <= 1'b0;
            bit_cnt   <= 5'd0;
            miso_sync <= 2'b00;
        end else begin
            miso_sync <= {miso_sync[0], miso};   // синхронізація MISO
            rx_valid  <= 1'b0;

            if (cs_n) begin
                bit_cnt <= 5'd0;                 // обмін не триває - очистити лічильник
            end else if (sample) begin
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso_sync[1]};
                if (bit_cnt == DATA_WIDTH - 1) begin
                    // отримано останній біт: зафіксувати слово
                    rx_data  <= {shift_reg[DATA_WIDTH-2:0], miso_sync[1]};
                    rx_valid <= 1'b1;
                    bit_cnt  <= 5'd0;
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

endmodule
