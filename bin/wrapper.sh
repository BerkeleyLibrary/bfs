dir=$PWD
while true 
do
  for file in $(ls $dir/in_dir) 
  do

  #for file in $dir/in_dir/*; do
    input_file="$(basename ${file})"
    ruby /opt/app-root/src/lib/invoice_parser.rb $input_file 
    
    sleep 2
  done
  
  sleep 60
done
