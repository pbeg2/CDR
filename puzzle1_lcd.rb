require 'i2c/drivers/lcd'

class LCDController
  def initialize
    @display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', 0x27, rows = 20, cols = 4)
  end

  def escribir_en_lcd(texto)
    @display.clear
    @display.set_justify(Gtk::Justification::CENTER)
    @display.text(texto, 1) 
    lineas = texto.chars.each_slice(20).map(&:join)
    lineas.each_with_index do |linea, index|
         @display.text(linea[0, 20], index)
    end
  end

end
