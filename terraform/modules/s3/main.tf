resource "aws_s3_bucket" "airflow_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "airflow-dags-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "airflow_bucket" {
  bucket = aws_s3_bucket.airflow_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "airflow_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.airflow_bucket]
  bucket = aws_s3_bucket.airflow_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "airflow_bucket" {
  bucket = aws_s3_bucket.airflow_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.airflow_bucket.id

  topic {
    topic_arn     = aws_sns_topic.airflow_dags_updates.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = "dags/"
  }
}

resource "aws_sns_topic" "airflow_dags_updates" {
  name = "airflow-dags-updates"
}