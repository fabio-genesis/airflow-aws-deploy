#!/bin/bash
set -e
docker build -f containers/prod/Dockerfile -t airflow-prod .
