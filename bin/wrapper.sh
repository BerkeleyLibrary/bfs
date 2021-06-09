dir=$PWD
while true 
do
  #for file in $(ls $dir/invoicing/pay) 
  for file in $(ls $dir/invoicing/pay -p | grep -v /)
  do
    input_file="$(basename ${file})"
    printf $input_file
    ruby /opt/app-root/src/lib/invoice_parser.rb $input_file 
    
    sleep 2
  done
  
  sleep 60
done
