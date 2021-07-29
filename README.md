# BFS Processor

A command-line tool for processing BFS .xml files. Input files can be mounted anywhere on the filesystem, but by default the program looks at `./data/invoicing/pay/*.xml`. Output files are written to `./data/processed` (originals and re-formatted files) and `./data/rejected` (error logs).

## Building the app

```sh
docker-compose build
```

## Running it

View the CLI tool help/description:

```sh
docker-compose run --rm bfs help
```

Adds test data to the default watch directory:

```sh
docker-compose run --rm bfs seed
```

Run the app in the background. It will continue running, monitoring for .xml files to process every 10s.

```sh
docker-compose up -d
docker-compose logs -f # view processing logs in real time
```

Watch a non-standard directory:

```sh
docker-compose run --rm bfs watch /path/in/container # absolute path
docker-compose run --rm bfs watch data/somedir # path relative to /opt/app-root/src
```

Process a specific file:

```sh
docker-compose run --rm bfs process /abs/path/to/myfile.xml # absolute path
docker-compose run --rm bfs process data/invoicing/pay/somefile.xml # relative path
```

Delete previously processed files and error logs:

```sh
docker-compose run --rm bfs clear
```
