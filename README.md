# BFS Processor

## Local Testing

```sh
# Build the container
docker-compose build

# Copy fixtures to data/in_dir
cp spec/fixtures/*.xml data/invoice/pay

# Run against one of the fixtures or any file put into /data/in_dir.
docker-compose run --rm --entrypoint=bundle bfs exec ruby ../src/invoice_parser.rb invoice_new_remit.xml

# Run the wrapper script which will loop through the /data/in_dir directory and process any files present.
# This is run continuously by default when the container is started.

docker-compose up 

```
