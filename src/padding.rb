module Padding
require 'yaml'

pad_file = File.join(File.dirname(__FILE__), './pad_settings.yml')

#pads the designated field with spaces or 0's left or right justified
#field_name is the name of the BFS field
#str is the string being processed
#pad_type is either a space or a 0
#adjust is either left adjusted or right adjusted so (ljust or rjust)
#def self.get_pad(field_name,str,pad_type,adjust)

def self.get_pad(field_name,str)

  pad = @pad_settings['pad_settings'][field_name]['pad']
  pad_type = @pad_settings['pad_settings'][field_name]['separator']
  adjust = @pad_settings['pad_settings'][field_name]['adjust']
  
  unless pad.nil? 
    if adjust == "rjust"
      str = str.rjust(pad,pad_type)
    elsif adjust == "ljust"
      str = str.ljust(pad,pad_type)
    end
  end

  return str
end


@pad_settings = YAML.load_file(pad_file)

end
