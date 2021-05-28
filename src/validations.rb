module Validations
require 'nokogiri'

def self.validate(invoice)
  errors = required_header_fields(invoice)
  errors << required_item_fields(invoice)
 
  return errors
end

#make sure certain fields don't exceed maximum size
def required_size(invoice_data)
 

end 

#make sure all required header fields are present. Each invoice has a single header
def self.required_header_fields(invoice)
  errors = "" 
  required = ["vendor_FinancialSys_Code","reference_voucher"]

  required.each do |field|
    unless invoice[field].length > 0 && invoice[field][0].to_s.match(/\w/)
      errors << "Invoice missing required field: #{field}\n" 
    end
  end

  return errors
end

#Make sure each item has required fields. Each invoice can have multiple items.
def self.required_item_fields(invoice)
  errors = "" 
  required = ["external_id","business_unit","account","fund","org","program"]  

  invoice_line_size = invoice['item_total_price'].size
  required.each do |field|
    elem = 0 
    while elem <= invoice_line_size - 1
     
      unless invoice[field][elem].to_s.match(/\w/) 
          errors << "Invoice missing required field: #{field}\n" 
      end
      elem += 1
    end  
  end

  return errors
end

end
