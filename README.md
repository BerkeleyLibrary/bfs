# BFS Processor

## Local Testing

```sh
# Build the container
docker-compose build

# Copy fixtures to data/in_dir
cp spec/fixtures/*.xml data/in_dir/

# Run against one of the fixtures.
docker-compose run --rm bfs invoice_multiple_items.xml # valid
docker-compose run --rm bfs invoice.xml # invalid
```
