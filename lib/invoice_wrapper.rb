home_dir = Dir.pwd

dir = "#{home_dir}/invoicing/pay"
Dir.foreach(dir) do |filename|
  next if filename == '.' or filename == '..'
  system("ruby src/invoice_parser.rb #{filename}")
  sleep 3 
end
