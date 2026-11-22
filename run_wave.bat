@echo off
rem Відкрити осцилограму в GTKWave з готовим набором сигналів
gtkwave sim\spi_wave.vcd -S gtkwave_setup.tcl
