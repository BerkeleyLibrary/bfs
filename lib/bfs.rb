# From rubygems
require 'date'
require 'fileutils'
require 'nokogiri'
# Specific to bfs
require 'docker'
require 'invoice_sections'
require 'invoice_tools'
require 'padding'
require 'validations'
require_relative 'mailer'
require_relative 'logging'
include Logging

# Loads secrets from /run/secrets/* into ENV
Docker::Secret.setup_environment!

module BFS
  DATA_DIR = File.expand_path(File.join(__dir__, '../data'))
  # Default directory to watch for files
  DEFAULT_INPUT_DIR = File.join(DATA_DIR, 'invoicing/pay')
  # Directory into which original files are placed after processing
  ORIGINALS_DIR = File.join(DATA_DIR, 'invoicing/pay/processed')
  # Directory into which output files are placed after processing
  OUTPUT_DIR = File.join(DATA_DIR, 'processed')
  # Directory into which error logs are placed after processing
  REJECTED_DIR = File.join(DATA_DIR, 'rejected')
  # Directory containing test/fixtures files
  FIXTURES_DIR = File.expand_path(File.join(__dir__, '../spec/fixtures'))

  def self.watch!(directory = nil, interval: 120)
    directory ||= DEFAULT_INPUT_DIR
    raise ArgumentError, "Watch directory '#{directory}' is not a directory or symlink to a directory" \
      unless File.directory?(directory) || \
             (File.symlink?(directory) && File.directory?(File.readlink(directory)))

    raise ArgumentError, "interval must be a positive integer" \
      unless interval > 0 and interval.to_i == interval

    pattern = File.expand_path(File.join(directory, '*.xml'))
    logger.info "BFS: Watching #{pattern} for updates"

    while true
      Dir.glob(pattern) do |filepath|
        begin
          logger.info "Processing file: #{filepath}"
          process!(filepath)
        rescue StandardError => e
          logger.info "Error processing #{filepath}: #{e}"
        end
      end

      logger.info "... pausing #{interval}s before checking for new files"
      sleep interval
    end
  end

  # Copies fixtures files into the default data directory
  def self.seed!
    Dir.glob("#{FIXTURES_DIR}/*.xml") do |filepath|
      FileUtils.cp(filepath, File.join(DEFAULT_INPUT_DIR, File.basename(filepath)))
    end
  end

  def self.clear!
    logger.info "Deleting .xml/.txt files under #{DATA_DIR}"
    FileUtils.rm_f(Dir.glob(File.join(DATA_DIR, '**/*.{txt,xml}')))
  end

  # Process an individual file
  def self.process!(in_file)
    # Path to the reformatted output file that will be created
    out_file = File.join(OUTPUT_DIR, File.basename(in_file).gsub('.xml', '.txt'))

    # Path to which the original file is moved post-processing
    done_file = File.join(ORIGINALS_DIR, File.basename(in_file))

    # Path to the file to which formatting errors are logged
    error_file = File.join(REJECTED_DIR, File.basename(in_file).gsub('.xml', '_errors.txt'))

    has_valid_invoice = false

    logger.info "Opening file for processing #{in_file} => #{out_file}"
    writer = File.open(out_file, 'w')

    doc = Nokogiri::XML(File.open(in_file), Encoding::UTF_8.to_s)
    doc.remove_namespaces!

    #process invoice, entry by entry
    invoice_count = 0
    item_count = 0
    grand_total = 0

    doc.xpath("//invoice").each do |data|
      invoice = Nokogiri::XML(data.to_xml)

      invoice_data = {}
      #invoice_data['external_id'] = InvoiceTools::get_items(invoice,"/invoice_line/fund_info_list/fund_info/external_id")
      invoice_data['external_id'] = InvoiceTools::get_items(invoice,"//fund_info_list/fund_info/external_id")
      invoice_data['invoice_number'] = InvoiceTools::get_data(invoice,"//invoice_number")
      invoice_data['vendor_FinancialSys_Code'] =  InvoiceTools::get_data(invoice,"//vendor_FinancialSys_Code")  #required
      #invoice_data['gross_amount'] = InvoiceTools::get_data(invoice,"//invoice_amount/sum")
      #invoice_data['item_total_price'] = InvoiceTools::get_data(invoice,"//fund_info_list/fund_info/local_amount/sum")
      #invoice_data['item_price'] = InvoiceTools::get_data(invoice,"//invoice_line_list/invoice_line/price")
      invoice_data['item_price'] = InvoiceTools::get_items(invoice,"/invoice_line/price")
      invoice_data['tax_code'] = InvoiceTools::parse_tax_code(invoice)
      #invoice_data['sales_tax'] = InvoiceTools::get_data(invoice,"//vat_info/vat_amount")
      invoice_data['sales_tax'] = InvoiceTools::get_items(invoice,"/invoice_line/vat_info/vat_amount")
      invoice_data['invoice_date'] = InvoiceTools::get_data(invoice,"//invoice_date")
      invoice_data['creation_date'] = InvoiceTools::get_data(invoice,"//invoice_ownered_entity/creationDate")
      invoice_data['overhead'] = InvoiceTools::get_data(invoice,"//additional_charges/overhead_amount")
      invoice_data['ship_amount'] = InvoiceTools::get_data(invoice,"//additional_charges/shipment_amount")
      invoice_data['remit_address_sequence'] = InvoiceTools::get_data(invoice,"/invoice/vendor_additional_code") #required, default is 0 if not present
      invoice_data['reference_voucher'] = InvoiceTools::get_data(invoice,"//unique_identifier") #required
      invoice_data['payment_method'] = InvoiceTools::get_data(invoice,"//payment_method")
      #invoice_data['line_number'] = InvoiceTools::get_data(invoice,"//invoice_line_list/invoice_line/line_number")
      invoice_data['line_number'] = InvoiceTools::get_items(invoice,"/invoice_line/line_number")

      #external id will be parsed and put into invoice_data hash for business unit, account, fund, org and program
      #invoice_data['external_id'] = InvoiceTools::get_data(invoice,"//fund_info_list/fund_info/external_id") #required, will be broken down into multiple fields
      InvoiceTools::parse_external(invoice_data)

      InvoiceTools::get_remit_to(invoice_data)

      errors = Validations::validate(invoice_data, invoice)
      if errors.any?
        logger.info "File has errors: #{errors} (#{in_file})"
        write_errorfile(invoice, errors, error_file)
        next
      end

      logger.info "... Invoice has no errors (#{invoice_data['invoice_number']})"
      has_valid_invoice = true

      invoice_data['sum'] = InvoiceTools::get_invoice_total(invoice_data)
      InvoiceTools::format_price(invoice_data,'sum')
      grand_total = invoice_data['sum'][0].to_i + grand_total
      #InvoiceTools::format_price(invoice_data,'item_total_price')
      InvoiceTools::format_price(invoice_data,'item_price')
      InvoiceTools::format_invoice_date(invoice_data)


      InvoiceTools::pad_fields(invoice_data)
      header = InvoiceSections::process_header(invoice_data)
      item_entries = InvoiceSections::process_invoice_entry(invoice_data)

      writer.write(header)
      writer.write(item_entries)

      invoice_count += 1
      #item_count += invoice_data['item_total_price'].length
      item_count += invoice_data['item_price'].length
    end

    if has_valid_invoice
      footer = InvoiceSections::process_footer(invoice_count, item_count, grand_total)
      writer.write(footer)
      writer.close
    else
      logger.info "Deleting output file because there are no valid invoices: #{out_file}"
      writer.close
      File.delete(out_file) if File.exist?(out_file)
    end

    logger.info "Moving #{in_file} => #{done_file}"
    FileUtils.mv(in_file, done_file)

    subject = "BFS Invoices file for #{in_file}"
    body = "Invoices file for #{in_file} as well as error file if any invoices were rejected. If all invoices were rejected there will only be an error file"

    #send email if there are any error or BFS files produced
    attachments = [out_file,error_file]
    Mailer.send_message(subject,body,attachments)
    
  end

  def self.write_errorfile(invoice, errors, error_file)
    logger.info "Writing errors to #{error_file}"
    File.open(error_file, "a") do |fh|
      fh.write("**********************\n")
      fh.write("\n#{errors.join}\n\n")
      fh.write(invoice)
      fh.write("**********************\n\n")
    end
  end
end
