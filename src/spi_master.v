`timescale 1ns / 1ps
//==============================================================================
// Файл    : spi_master.v
// Модуль  : spi_master - верхній модуль SPI Master (режим 0)
//
// Об'єднує передавач spi_tx і приймач spi_rx. Це дуплексний обмін: під час
// передачі слова tx_data по MOSI одночасно приймається слово зі Slave по MISO.
//
// Порти:
//   clk, rst      - такт і синхронне скидання (активний рівень 1);
//   start         - імпульс запуску обміну (1 такт);
//   tx_data       - слово для передачі;
//   rx_data       - прийняте слово, rx_valid - імпульс його готовності;
//   busy / done   - обмін триває / обмін завершено (імпульс);
//   sck, mosi, cs_n, miso - лінії інтерфейсу SPI.
//==============================================================================
module spi_master #(
    parameter DATA_WIDTH = 8,   // розрядність слова
    parameter CLK_DIV    = 4    // тактів clk у півперіоді SCK
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire                  miso,
    output wire                  sck,
    output wire                  mosi,
    output wire                  cs_n,
    output wire                  busy,
    output wire                  done,
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire                  rx_valid
);

    wire sck_rise;   // імпульс від передавача: SCK щойно став 1

    spi_tx #(
        .DATA_WIDTH (DATA_WIDTH),
        .CLK_DIV    (CLK_DIV)
    ) u_tx (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .tx_data  (tx_data),
        .sck      (sck),
        .mosi     (mosi),
        .cs_n     (cs_n),
        .busy     (busy),
        .done     (done),
        .sck_rise (sck_rise)
    );

    spi_rx #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_rx (
        .clk      (clk),
        .rst      (rst),
        .sample   (sck_rise),
        .cs_n     (cs_n),
        .miso     (miso),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

endmodule
