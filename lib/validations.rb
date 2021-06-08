module Validations
require 'nokogiri'
require 'date'

def self.validate(invoice)
  errors = required_header_fields(invoice)
  errors << required_item_fields(invoice)
  errors << required_size(invoice,'vendor_FinancialSys_Code',10) 
  errors << payment_method(invoice)
  errors << invoice_date_valid(invoice['invoice_date'][0])
  return errors
end

def self.invoice_date_valid(invoice_date)
  errors = ""
  
  invoice_date = Date.strptime(invoice_date, "%m/%d/%Y")

  now_date = Time.now.strftime("%F")
  invoice_date = invoice_date.strftime("%F")

  a = Date.parse(invoice_date)
  b = Date.parse(now_date)

  diff = a.mjd - b.mjd

  if diff > 7
    errors << "invoice date #{invoice_date} is greater than 7 days away" 
  end

  return errors
end

def self.payment_method(invoice)
  errors = ""
  unless invoice['payment_method'][0].to_s.match(/ACCOUNTINGDEPARTMENT/i)
    errors << "Payment method is incorrect. payment_method is required and can only be ACCOUNTINGDEPARTMENT"
  end

  return errors
end


#make sure certain fields don't exceed maximum size
def self.required_size(invoice_data,field,size)
  errors = ""
  invoice_data[field].each do |value|
    unless value.size == size 
      errors << "#{field} is wrong size for #{value}. Should be #{size} characters" 
    end 
  end 
  return errors
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

 # invoice_line_size = invoice['item_total_price'].size
  invoice_line_size = invoice['item_price'].size
  required.each do |field|
    elem = 0 
    while elem <= invoice_line_size - 1
     
      unless invoice[field][elem].to_s.match(/\w/) 
          
          errors << "Invoice missing required field: #{field}. line number #{invoice['line_number'][elem]}\n" 
          #errors << "Invoice missing required field: #{field}."
      end
      elem += 1
    end  
  end

  return errors
end

end
