require 'i2c/drivers/lcd'

class LCDController
  def initialize
    @display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', 0x27, rows = 20, cols = 4)
  end

  def escribir_en_lcd(texto)
    @display.clear
    lineas = texto.chars.each_slice(20).map(&:join)
    lineas.each_with_index do |linea, index|
         @display.text(linea[0, 20], index)
    end
  end
  def escribir_en_lcd_centrado(mensaje)
    # Calcula cuántos espacios en blanco necesitas agregar al principio del mensaje
    espacios_en_blanco = [(20 - mensaje.length) / 2, 0].max

    # Construye el mensaje centrado con espacios en blanco al principio
    mensaje_centrado = " " * espacios_en_blanco + mensaje

    # Escribir el mensaje centrado en la pantalla LCD
    escribir_en_lcd(mensaje_centrado)
  end
end

