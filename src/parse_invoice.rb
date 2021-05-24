require 'nokogiri'
require 'date'
require_relative 'padding'

#file = "./invoice_multiple_items.xml"
#file = "./invoice.xml"
file = "./invoices_complicated.xml"
file = ARGV[0]


doc = Nokogiri::XML(File.open(file),Encoding::UTF_8.to_s)
doc.remove_namespaces!

#format date. It needs to be yymmdd
def process_date(invoice_date)
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
def repeated(string,repeats)
  string = Array.new(repeats,string).join("")
  return string
end

#Some invoices items have negative prices. 
def process_sign(value)
  if value.match?(/-/)
    return value.gsub("-","0"),"-"
  else
    return value," " 
  end
end

#create header string
def process_header(invoice_data)

  invoice_price,sign = process_sign(invoice_data['sum'][0].to_s)

  header = "2L"
  header << invoice_data['vendor_FinancialSys_Code'][0].to_s
  header << invoice_data['invoice_number'][0].to_s
  header << "000000" #line item number (for 3) and distsequence number (for 3)
  header << invoice_data['invoice_date'][0].to_s
  #header << invoice_data['sum'][0].to_s
  header << invoice_price
  header << sign #either blank or "-" if it's a negative invoice
  header << "S3" 
  header << repeated(" ",17) #Inventory description. not used 
  header << repeated(" ",26) #Filler
  header << invoice_data['remit_address_sequence'][0].to_s #need to find this, I see "A" as well as "2" 
  header << " " #pickup id. not used
  header << invoice_data['reference_voucher'][0].to_s.slice(0,10) #using first 10 digits of unique identifier
  header << repeated(" ",6) #due date not used 
  header << "01 " #payment terms fixed 
  header << "000" #payment terms days not used
  header << repeated(" ",5) #discount percent not used
  header << repeated(" ",3) #discount days not used
  header << repeated(" ",29) #filler
  header << "\n" 
  
  puts header 

end

def process_invoice_entry(invoice_data)
  line_item_number = "001" 
  item_count = 1

  count = 0
  #we will supply an invidual line for each gross_amount 
  invoice_data['item_total_price'].each do |value| 
  
    #get the invoice price and sign (either negative, or blank for positive) 
    invoice_item_price,sign = process_sign(value)

    dist = "2L"    
    dist << invoice_data['vendor_FinancialSys_Code'][0].to_s
    dist << invoice_data['invoice_number'][0].to_s
    dist << line_item_number
    dist << Padding::get_pad('dist_sequence',item_count.to_s) 
    dist << repeated(" ",17) #filler
#    dist << value 
    dist << invoice_item_price
    dist << sign
    dist << repeated("0",10) #lien, we never use those
    dist << sign
    dist << repeated(" ",4) #filler
    dist << repeated(" ",2) #10 99 tax code, not used
    #dist << repeated(" ",2) #tax code (need to find this and add in)
    dist << "A "  #tax code. hard coding A for testing need to add this in when know
    dist << repeated(" ",8) #filler
    dist << repeated(" ",10) #speed type not used
    dist << invoice_data['business_unit'][count].to_s
    dist << repeated(" ",4) #filler
    dist << invoice_data['account'][count].to_s
    dist << " " #filler
    dist << invoice_data['fund'][count].to_s
    dist << invoice_data['org'][count].to_s
    dist << repeated(" ",5) #filler
    dist << invoice_data['program'][count].to_s
    dist << repeated(" ",3) #filler
    dist << " " #subprogram (not sure what this would be). seems to always be blank
    dist << repeated(" ",4) #filler
    dist << repeated(" ",5) #project, innopac doesn't support project yet
    dist << repeated(" ",10) #filler
    dist << repeated(" ",5) #flex, innopac doesn't support flex yet
    dist << repeated(" ",11) #flex, innopac doesn't support flex yet
    
    dist << "\n"

    item_count += 1 
    puts dist

    count += 1
  end 

end

def write_footer(invoice_count,item_count,grand_total)
  invoice_grand_total,sign = process_sign(grand_total.to_s)
 
  footer = "2L"
  footer << "9999999999" #vendor
  footer << "999999999999" #inventory number
  footer << "999" #line item number
  footer << "999" #Dist sequence number
  footer << Padding::get_pad("invoice_count",invoice_count.to_s) #number of invoices
  footer << Padding::get_pad("grand_total",invoice_grand_total)
  footer << sign 
  footer << "000000" #number of line item records 
  footer << "00000000000000" #total line item dollar amount
  footer << " " #total line sign 
  footer << Padding::get_pad("item_count",item_count.to_s)
  footer << Padding::get_pad("grand_total",invoice_grand_total) #//total distribution amount (same as total invoice amount).
  footer << sign 
  footer << repeated(" ",67) #filler
 
 puts footer 
  
end

def parse_external(invoice_data)
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
def pad_fields(invoice_data)
  
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
def handle_error(msg,fatal=false)
  #puts msg
  #todo write to log file
end

def get_data(invoice,xpath,required=true)
  line_items = []
  invoice.xpath(xpath).each do |line|
    line_items << line.text
  end

  if line_items.empty? && required
    handle_error("Can't find #{xpath} in #{invoice}")
    return line_items
  end
  
  return line_items
end

def format_invoice_date(invoice_data)
  elem = 0
  invoice_data['invoice_date'].each do |value|
    invoice_date = process_date(value)
    invoice_data['invoice_date'][elem] = invoice_date
    elem += 0
  end 
end

def get_invoice_total(invoice_data)
  sum = 0
  invoice_data['item_total_price'].each do |value|
    sum += value.to_f
    sum = sum.round(2)
  end
  sums = [sum.to_s] 
  
  return sums 
end

def get_remit_to(invoice_data)
  testy = ["A"]
  if invoice_data['vendor_FinancialSys_Code'][0].to_s.match(/(.*?)\-(\d+)$/)
    invoice_data['vendor_FinancialSys_Code'][0] = $1
    #invoice_data['remit_address_sequence'][0] = [$2]
    testy[0] = $2
  end 

    invoice_data['remit_address_sequence'] = testy
 # if invoice_data['vendor_FinancialSys_Code'][0].to_s.match(/(.*?)\-(\d+)$/)
end

def format_price(invoice_data,type)
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


#process invoice, entry by entry
invoice_count = 0
item_count = 0
grand_total = 0

doc.xpath("//invoice").each do |data|
  invoice = Nokogiri::XML(data.to_xml) 
  
  invoice_data = {} 
  invoice_data['invoice_number'] = get_data(invoice,"//invoice_number") 
# invoice_data['vendor_sys_code'] =  get_data(invoice,"//vendor_FinancialSys_Code",false) 
 #invoice_data['vendor_sys_code'] = Padding::get_pad("vendor_id",invoice_data['vendor_sys_code'].to_s,"0","rjust")
  invoice_data['vendor_FinancialSys_Code'] =  get_data(invoice,"//vendor_FinancialSys_Code") 
  #invoice_data['gross_amount'] = get_data(invoice,"//invoice_amount/sum") 
  invoice_data['item_total_price'] = get_data(invoice,"//fund_info_list/fund_info/local_amount/sum") 
  #invoice_data['item_total_price'] = get_data(invoice,"//price") 
  invoice_data['sales_tax'] = get_data(invoice,"//vat_info/vat_amount") 
  invoice_data['invoice_date'] = get_data(invoice,"//invoice_date") 
  invoice_data['creation_date'] = get_data(invoice,"//invoice_ownered_entity/creationDate") 
  invoice_data['overhead'] = get_data(invoice,"//additional_charges/overhead_amount") 
  invoice_data['ship_amount'] = get_data(invoice,"//additional_charges/shipment_amount") 
  invoice_data['reference_voucher'] = get_data(invoice,"//unique_identifier") 

  #external id will be parsed and put into invoice_data hash for business unit, account, fund, org and program 
  invoice_data['external_id'] = get_data(invoice,"//fund_info_list/fund_info/external_id") 
  parse_external(invoice_data)

  #is parsed from vendor_FinacialSys_Code (default is "A", if ends in "-digits) it will use digits after the dash
  get_remit_to(invoice_data)

  invoice_data['sum'] = get_invoice_total(invoice_data)
  format_price(invoice_data,'sum')
  grand_total = invoice_data['sum'][0].to_i + grand_total 
  format_price(invoice_data,'item_total_price')
  format_invoice_date(invoice_data)
  pad_fields(invoice_data)
  process_header(invoice_data)
  process_invoice_entry(invoice_data)

  invoice_count += 1
  item_count += invoice_data['item_total_price'].length

end

write_footer(invoice_count,item_count,grand_total)
