require 'i2c/drivers/lcd'

class LCDController
  def initialize
    @display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', 0x27, rows = 20, cols = 4)
  end

  def escribir_en_lcd(texto)
    @display.clear
    lineas = texto.split("\n")
    lineas.each_with_index do |linea, index|
         @display.text(linea[0, 20], index)
    end
  end

end
