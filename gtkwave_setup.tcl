# Налаштування GTKWave: додати потрібні сигнали та показати весь час симуляції
set sigs {
  tb_spi_master.clk
  tb_spi_master.rst
  tb_spi_master.start
  {tb_spi_master.tx_data[7:0]}
  tb_spi_master.cs_n
  tb_spi_master.sck
  tb_spi_master.mosi
  tb_spi_master.miso
  tb_spi_master.busy
  tb_spi_master.done
  tb_spi_master.rx_valid
  {tb_spi_master.rx_data[7:0]}
  {tb_spi_master.slave_reply[7:0]}
  {tb_spi_master.slave_received[7:0]}
}
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
