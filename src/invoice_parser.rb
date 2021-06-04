require 'nokogiri'
require 'date'
require 'fileutils'
require_relative 'padding'
require_relative 'validations'
require_relative 'invoice_sections'
require_relative 'invoice_tools'

now = Time.now.utc.strftime("%Y%m%d%H%M%S")
input_file = ARGV[0]

home_dir = Dir.pwd
in_dir = "#{home_dir}/in_dir"
processed_dir = "#{home_dir}/processed"
log_dir = "#{home_dir}/log_dir"
@out_file = "#{processed_dir}/BFSINPUT#{now}.txt"

@error_file = "#{log_dir}/BFSINPUT#{now}_errors.txt"
@has_valid_invoice = false
@writer = File.open(@out_file,"w")

def self.handle_errors(invoice,errors)
  write_errors = File.open(@error_file,"a")
 
  write_errors.write("**********************\n") 
  write_errors.write("\n#{errors}\n\n")
  write_errors.write(invoice)
  write_errors.write("**********************\n\n") 

  write_errors.close
end

doc = Nokogiri::XML(File.open("#{in_dir}/#{input_file}"),Encoding::UTF_8.to_s)
doc.remove_namespaces!

#process invoice, entry by entry
invoice_count = 0
item_count = 0
grand_total = 0

doc.xpath("//invoice").each do |data|
  invoice = Nokogiri::XML(data.to_xml) 
  
  invoice_data = {} 
  invoice_data['invoice_number'] = InvoiceTools::get_data(invoice,"//invoice_number") 
  invoice_data['vendor_FinancialSys_Code'] =  InvoiceTools::get_data(invoice,"//vendor_FinancialSys_Code")  #required
  #invoice_data['gross_amount'] = InvoiceTools::get_data(invoice,"//invoice_amount/sum") 
  invoice_data['item_total_price'] = InvoiceTools::get_data(invoice,"//fund_info_list/fund_info/local_amount/sum") 
  invoice_data['sales_tax'] = InvoiceTools::get_data(invoice,"//vat_info/vat_amount") 
  invoice_data['invoice_date'] = InvoiceTools::get_data(invoice,"//invoice_date") 
  invoice_data['creation_date'] = InvoiceTools::get_data(invoice,"//invoice_ownered_entity/creationDate") 
  invoice_data['overhead'] = InvoiceTools::get_data(invoice,"//additional_charges/overhead_amount") 
  invoice_data['ship_amount'] = InvoiceTools::get_data(invoice,"//additional_charges/shipment_amount") 
  invoice_data['remit_address_sequence'] = InvoiceTools::get_data(invoice,"//vendor_additional_code") #required, default is A if not present
  invoice_data['reference_voucher'] = InvoiceTools::get_data(invoice,"//unique_identifier") #required 

  #external id will be parsed and put into invoice_data hash for business unit, account, fund, org and program 
  invoice_data['external_id'] = InvoiceTools::get_data(invoice,"//fund_info_list/fund_info/external_id") #required, will be broken down into multiple fields
  InvoiceTools::parse_external(invoice_data)

  #is parsed from vendor_FinacialSys_Code (default is "A", if ends in "-digits) it will use digits after the dash
  InvoiceTools::get_remit_to(invoice_data)

  errors = Validations::validate(invoice_data)
  if errors.empty?
    @has_valid_invoice = true
  else
    handle_errors(invoice,errors)
    next
  end


  invoice_data['sum'] = InvoiceTools::get_invoice_total(invoice_data)
  InvoiceTools::format_price(invoice_data,'sum')
  grand_total = invoice_data['sum'][0].to_i + grand_total 
  InvoiceTools::format_price(invoice_data,'item_total_price')
  InvoiceTools::format_invoice_date(invoice_data)


  InvoiceTools::pad_fields(invoice_data)
  header = InvoiceSections::process_header(invoice_data)
  item_entries = InvoiceSections::process_invoice_entry(invoice_data)

  @writer.write(header)
  @writer.write(item_entries)

  invoice_count += 1
  item_count += invoice_data['item_total_price'].length
end

if @has_valid_invoice
  footer = InvoiceSections::process_footer(invoice_count,item_count,grand_total)
  @writer.write(footer)
  @writer.close
  FileUtils.mv("#{in_dir}/#{input_file}","#{processed_dir}/source_files/#{input_file}") 
else
  File.delete(@out_file) if File.exist?(@out_file)
  FileUtils.mv("#{in_dir}/#{input_file}","#{processed_dir}/source_files/#{input_file}_error") 
end
