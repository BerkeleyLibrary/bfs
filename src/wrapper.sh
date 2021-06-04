dir=$PWD
while true 
do
  for file in $(ls $dir/in_dir) 
  do

  #for file in $dir/in_dir/*; do
    input_file="$(basename ${file})"
    ruby /opt/app-root/src/src/invoice_parser.rb $input_file 
    #ruby /opt/app-root/src/src/invoice_parser.rb "${file##*/}"
    #echo "${file##*/}"
    echo $input_file
    sleep 2
  done
  
  sleep 60
done
