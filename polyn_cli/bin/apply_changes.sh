#!/bin/bash

# We want to keep these commands out of the Docker image
# build and instead defer them till the container is run.
# terraform init may require credentials for a remote backend
# and we don't want that in the image for security reasons.
bundle exec polyn tf_init
bundle exec polyn up