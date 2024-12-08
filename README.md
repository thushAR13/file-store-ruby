# File Store Service

## Overview

This is a file store service built with Ruby on Rails that provides an HTTP server and a command-line client (CLI) for managing plain-text files. The service allows you to:

- **Add files** to the server.
- **List stored files.**
- **Delete files** by name.
- **Update file contents.**
- Perform operations like **word count** and **finding the most frequent words**.

The service is optimized to avoid uploading duplicate file contents by using **SHA256 hashing** to detect existing files on the server.

---

## Installation and Setup

### Prerequisites

- **Ruby** (>= 3.1)
- **Rails** (>= 7.0)
- **PostgreSQL**
- **Docker** (optional)

### Clone the Repository

```bash
git clone <repository_url>
cd file_store
```

### Install Dependencies

```bash
bundle install
```

### Configure the Database

1. Edit the `config/database.yml` file to set up your PostgreSQL credentials.
2. Create the database:

   ```bash
   rails db:create
   rails db:migrate
   ```

### Start the Server

```bash
rails server
```

The server will start at [http://localhost:3000](http://localhost:3000).

---

## CLI Usage

The CLI client is located in `cli/file_store_client.rb`. Below are the available commands:

### Add Files

```bash
ruby cli/file_store_client.rb add <file_path1> <file_path2> ...
```

- Uploads one or more files to the server.
- Optimized to reuse existing content if a file with the same content exists on the server.

### List Files

```bash
ruby cli/file_store_client.rb list
```

- Retrieves a list of all stored files.

### Delete a File

```bash
ruby cli/file_store_client.rb delete <file_name>
```

- Deletes a file by name.

### Update a File

```bash
ruby cli/file_store_client.rb update <file_path>
```

- Updates the contents of a file on the server.

### Word Count

```bash
ruby cli/file_store_client.rb word_count
```

- Returns the total number of words across all files.

### Frequent Words

```bash
ruby cli/file_store_client.rb freq_words [limit] [order]
```

- **limit**: Number of words to retrieve (default: 10).
- **order**: `asc` for least frequent, `desc` for most frequent (default: `desc`).

---

## For Kubernetes

### Prerequisites

- Kubernetes cluster (e.g., Minikube, Kind, or a cloud provider)
- PostgreSQL database
- Docker for building and pushing application images

### Environment Variables

The following environment variables must be set via Kubernetes ConfigMaps and Secrets:

- **BASE_URL**: From ConfigMap (`stored-files-config`).
- **SECRET_KEY_BASE**: From Secret (`stored-files-secret`).
- **POSTGRES_PASSWORD**: From Secret (`postgres-secret`).

### Database Setup

Run the following commands to set up the database:

```bash
kubectl exec -it <pod-name> -- bundle exec rails db:create
kubectl exec -it <pod-name> -- bundle exec rails db:migrate
```

---

## Troubleshooting

### Error: `secret "postgres-secret" not found`

- Ensure the secret is created as described in the Secrets section.

### Connection Issues

- Verify database credentials and connectivity:
  - The database must be running and accessible at the `POSTGRES_HOST` specified in your deployment.
  - Check if the password in `postgres-secret` matches the database user password.

## Docker Image

This service is available as a Docker image:

- **Docker Hub**: [your-dockerhub-thushar13/stored-files-service](https://hub.docker.com/r/thushar13/stored-files-service)

To pull the image:
```bash
docker pull
thushar13/stored-files-service:latest

