dir=$PWD
while true 
do
  for file in $(ls -p ../data/invoicing/pay | grep -v /)
  do
    input_file="$(basename ${file})"
    #ruby /opt/app-root/src/lib/invoice_parser.rb $input_file 
    ruby ../lib/invoice_parser.rb $input_file 
    sleep 2
  done
  sleep 60 
done
