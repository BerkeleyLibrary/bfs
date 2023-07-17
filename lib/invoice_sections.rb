require_relative 'invoice_tools'
require_relative 'padding'
require_relative 'logging'
include Logging

module InvoiceSections
  #create header string
  def self.process_header(invoice_data)
    logger.info "Going to create header for #{invoice_data['invoice_number'][0].to_s}"
    invoice_price,sign = InvoiceTools::process_sign(invoice_data['sum'][0].to_s)

    header = "2L"
    header << invoice_data['vendor_FinancialSys_Code'][0].to_s
    header << invoice_data['invoice_number'][0].to_s
    header << "000000" #line item number (for 3) and distsequence number (for 3)
    header << invoice_data['invoice_date'][0].to_s
    #header << invoice_data['sum'][0].to_s
    header << invoice_price
    header << sign #either blank or "-" if it's a negative invoice
    header << "S3"
    header << InvoiceTools::repeated(" ",17) #Inventory description. not used
    header << InvoiceTools::repeated(" ",26) #Filler
    header << invoice_data['remit_address_sequence'][0].to_s
    header << " " #pickup id. not used
    header << invoice_data['reference_voucher'][0].to_s.slice(0,10) #using first 10 digits of unique identifier
    header << InvoiceTools::repeated(" ",6) #due date not used
    header << "01 " #payment terms fixed
    header << "000" #payment terms days not used
    header << InvoiceTools::repeated(" ",5) #discount percent not used
    header << InvoiceTools::repeated(" ",3) #discount days not used
    header << InvoiceTools::repeated(" ",29) #filler
    header << "\n"
    logger.info "Finished with header for #{invoice_data['invoice_number'][0].to_s}"
   # puts header
    return header
    #@writer.write(header)
  end

  def self.process_invoice_entry(invoice_data)
   
    line_item_number = "001"
    item_count = 1
    invoices = ""

    logger.info "Going to create invoice"

    count = 0
    #we will supply an invidual line for each gross_amount
    #invoice_data['item_total_price'].each do |value|
    invoice_data['item_price'].each do |value|

      #get the invoice price and sign (either negative, or blank for positive)
      invoice_item_price,sign = InvoiceTools::process_sign(value)

      dist = "2L"
      dist << invoice_data['vendor_FinancialSys_Code'][0].to_s
      dist << invoice_data['invoice_number'][0].to_s
      dist << line_item_number
      dist << Padding::get_pad('dist_sequence',item_count.to_s)
      dist << InvoiceTools::repeated(" ",17) #filler
  #    dist << value
      dist << invoice_item_price
      dist << sign
      dist << InvoiceTools::repeated("0",10) #lien, we never use those
      dist << sign
      dist << InvoiceTools::repeated(" ",4) #filler
      dist << InvoiceTools::repeated(" ",2) #10 99 tax code, not used
      #dist << "A "  #tax code. hard coding A for testing need to add this in when know
      dist << invoice_data['tax_code'][count].to_s  #tax code. hard coding A for testing need to add this in when know
      dist << InvoiceTools::repeated(" ",8) #filler
      dist << InvoiceTools::repeated(" ",10) #speed type not used
      dist << invoice_data['business_unit'][count].to_s
      dist << InvoiceTools::repeated(" ",4) #filler
      dist << invoice_data['account'][count].to_s
      dist << " " #filler
      dist << invoice_data['fund'][count].to_s
      dist << invoice_data['org'][count].to_s
      dist << InvoiceTools::repeated(" ",5) #filler
      dist << invoice_data['program'][count].to_s
      dist << InvoiceTools::repeated(" ",8) #filler
      dist << invoice_data['cf1'][count].to_s
      dist << InvoiceTools::repeated(" ",9) #filler
      dist << invoice_data['cf2'][count].to_s
      dist << InvoiceTools::repeated(" ",11) #flex, innopac doesn't support flex yet

      dist << "\n"

      invoices << dist
      item_count += 1
      #puts dist
      #@writer.write(dist)
      logger.info "#{count + 1} line items for invoice for #{invoice_data['invoice_number'][0].to_s}"
      count += 1
    end

    return invoices
  end

  def self.process_footer(invoice_count,item_count,grand_total)
    logger.info "creating footer"
    invoice_grand_total,sign = InvoiceTools::process_sign(grand_total.to_s)

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
    footer << InvoiceTools::repeated(" ",67) #filler
    
    logger.info "Finished with Footer"
    return footer
  end
end
