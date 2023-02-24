require 'date'
require 'nokogiri'
require_relative 'logging'
require_relative 'validate_COA'
include Logging

module Validations
  def self.validate(invoice, invoice_xml)
    logger.info "Validating invoice #{invoice['invoice_number'][0].to_s}"
    errors = []
    errors << required_header_fields(invoice)
    errors << max_size(invoice,'vendor_FinancialSys_Code',10)
    errors << max_size(invoice,'invoice_number',12)
    errors << multiple_chart_strings(invoice,invoice_xml)
    errors << external_id_format(invoice)
    errors << payment_method(invoice)
    errors << currency(invoice, invoice_xml)
    errors << invoice_date_valid(invoice['invoice_date'][0])
    return errors.reject { |e| e.to_s.length == 0 }
    logger.info "Finished validations for invoice #{invoice['invoice_number'][0].to_s}"
  end

  def self.currency(invoice, invoice_xml)
    logger.info "Checking that currency is USD for #{invoice['invoice_number'][0].to_s}"
    errors = '' 
    count = 0

    invoice_xml.xpath("//invoice_line").each do |line|
      xml = Nokogiri::XML(line.to_xml)
      value = ""
      items = []
      xml.xpath("//fund_info_list/fund_info/amount/currency").each do |field|
        value = field.text
        unless value.match(/^USD$/i)
          items << value
        end
      end
      
      errors << "Non USD currency found in invoice. Line number #{invoice['line_number'][count]}\n" unless items.empty?
      count += 1
    end
    
    return errors
  end

  def self.multiple_chart_strings(invoice,invoice_xml)
    logger.info "Checking for multiple chart strings for #{invoice['invoice_number'][0].to_s}"
    errors = ""
    count = 0
    invoice_xml.xpath("//invoice_line").each do |line|
      xml = Nokogiri::XML(line.to_xml)
      value = ""
      items = []
      xml.xpath("//fund_info_list/fund_info/external_id").each do |field|
        value = field.text
        items << value
      end
      if items.uniq.length > 1
        errors << "There are differing chart strings in a line item. line number #{invoice['line_number'][count]}\n"
      end
      count += 1
    end

    return errors
  end

  def self.invoice_date_valid(invoice_date)
    errors = ""

    if invoice_date.match(/\d{,2}\/\d{2}\/\d{4}/)
      invoice_date = Date.strptime(invoice_date, "%m/%d/%Y")
    elsif invoice_date.match(/\d{8}/)
      invoice_date = Date.strptime(invoice_date, "%Y%m%d")
    end

    now_date = Time.now.strftime("%F")
    invoice_date = invoice_date.strftime("%F")

    a = Date.parse(invoice_date)
    b = Date.parse(now_date)

    diff = a.mjd - b.mjd

    if diff > 7
      errors << "invoice date #{invoice_date} is greater than 7 days away\n"
    end

    return errors
  end

  def self.payment_method(invoice)
    logger.info "validating payment method #{invoice['invoice_number'][0].to_s}"
    errors = ""
    unless invoice['payment_method'][0].to_s.match(/ACCOUNTINGDEPARTMENT/i)
      errors << "Payment method is incorrect. payment_method is required and can only be ACCOUNTINGDEPARTMENT\n"
    end

    return errors
  end

  #make sure certain fields are an exact size
  def self.required_size(invoice_data,field,size)
    errors = ""
    invoice_data[field].each do |value|
      unless value && value.size == size
        errors << "#{field} is wrong size for #{value}. Must be #{size} characters\n"
      end
    end

    return errors
  end

  #make sure certain fields don't exceed maximum size
  def self.max_size(invoice_data,field, size)
    logger.info "Validating max size for field #{field} for #{invoice_data['invoice_number'][0].to_s}"
    errors = ""
    invoice_data[field].each do |value|
      if value && value.size > size
        errors << "#{field} is wrong size for #{value}. Exceeds #{size} characters\n"
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

  def self.external_id_format(invoice)
    logger.info "Validating external id format for #{invoice['invoice_number'][0].to_s}" 
    errors = ""
    count = 0

    invoice['external_id'].each do |value|
      status = ValidateCOA.get_status(value.to_s)

      unless value.to_s.match(/\w{1,}/)
        errors << "Missing external id (chart string). line number: #{invoice['line_number'][count]} for invoice: #{invoice['invoice_number'][0].to_s}\n"
        count += 1
        next
      end

      unless status.empty?
        errors << "#{status} for chart string: #{value.to_s}. line number: #{invoice['line_number'][count]} for invoice: #{invoice['invoice_number'][0].to_s}\n"
      end

      count += 1
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
            errors << "Invoice missing required field: #{field}. line_number: #{invoice['line_number'][elem]}\n"
            #errors << "Invoice missing required field: #{field}."
        end
        elem += 1
      end
    end

    return errors
  end
end
