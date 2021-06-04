module InvoiceTools

#format date. It needs to be yymmdd
def self.process_date(invoice_date)
  formats = ['%m/%d/%Y','%m.%d.%Y','%m-%d-%Y','%Y.%m.%d','%Y-%m-%d','%Y/%m/%d','%Y-%m','%b %d, %Y','%b %Y']
  formats.each do |format|
    begin
      if Date.strptime(invoice_date,format)
        d = Date.strptime(invoice_date,format)
        invoice_date = d.strftime('%y%m%d')
        return invoice_date
      end
    rescue
      next
    end
  end
  return invoice_date
end

#For added white space
def self.repeated(string,repeats)
  string = Array.new(repeats,string).join("")
  return string
end

#Some invoices items have negative prices. 
def self.process_sign(value)
  if value.match?(/-/)
    return value.gsub("-","0"),"-"
  else
    return value," " 
  end
end


def self.parse_external(invoice_data)
  business_units = []
  accounts = []
  funds = []
  orgs = []
  programs = []

  invoice_data['external_id'].each do |value| 
    value.to_s.match(/(\d)-(\d+)-(\d+)-(\d+)-(\d+)/)
    business_units <<  $1 
    accounts << $2 
    funds << $3 
    orgs << $4 
    programs << $5 
  end

  invoice_data['business_unit'] = business_units 
  invoice_data['account'] = accounts 
  invoice_data['fund'] = funds 
  invoice_data['org'] = orgs 
  invoice_data['program'] = programs 

end

#Pad fields to match BFS field specs
def self.pad_fields(invoice_data)
  
  invoice_data.each do |key,values|
    elem = 0

    #no value. set to empty string so proper empty or 0 padding will be 
    #entered for field
    if values.empty?
      values[elem] = "" 
    end

    values.each do |value|
      values[elem] = Padding::get_pad(key,value.to_s)
      elem += 1
    end

    invoice_data[key] = values
  end
  
end

#Will log error, if fatal flag will stop processing
def handle_error(msg,invoice,fatal=false)
  puts msg 
  puts invoice
  #todo write to log file
end

def handle_errors(invoice,errors)
  
  write_errors = File.open(@error_file,"a")
 
  write_errors.write("**********************\n") 
  write_errors.write("\n#{errors}\n\n")
  write_errors.write(invoice)
  write_errors.write("**********************\n\n") 

  write_errors.close
end

def self.get_data(invoice,xpath,required=false)
  line_items = []
  errors = ""
 
  invoice.xpath(xpath).each do |line|
    line_items << line.text
  end

  if line_items.empty? && required
    errors << "Can't file path for #{xpath}"
    #handle_error("Can't find #{xpath}",invoice,required)
    #return line_items
  end
  
  return line_items
end

def self.format_invoice_date(invoice_data)
  elem = 0
  invoice_data['invoice_date'].each do |value|
    invoice_date = process_date(value)
    invoice_data['invoice_date'][elem] = invoice_date
    elem += 0
  end 
end

def self.get_invoice_total(invoice_data)
  sum = 0
  invoice_data['item_total_price'].each do |value|
    sum += value.to_f
    sum = sum.round(2)
  end
  sums = [sum.to_s] 
  
  return sums 
end

#Get the shipment id from the shipment note. Anything after Remit:, Otherwise it will default to "A"
def self.get_remit_to(invoice_data)
  shipment_id = "A"
  
  if invoice_data['remit_address_sequence'][0].to_s.match(/REMIT\:\s{0,}(\w.*?)$/i)
    shipment_id =  $1
  end 
 
  invoice_data['remit_address_sequence'][0] = shipment_id
end


def self.format_price(invoice_data,type)
  elem = 0
 
  invoice_data[type].each do |value|
    
    if value.match(/\.\d{2}/)
      value.gsub!(/\./,"")
    elsif value.match(/\.\d{1}/)
      value.gsub!(/\./,"")
      value.gsub!(/$/,"0")
    else
      value.gsub!(/$/,"00")
    end
    
    invoice_data[type][elem] = value
    elem += 1 
  end 
end

end
