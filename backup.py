
import os
import shutil

from datetime import  datetime
from time import sleep

import boto3
import schedule

VOLUME_PATH = '/opt/railway/.flowise'
BACKUP_PATH = 'backups'
S3_BUCKET = 'geenuity-railway-backups'
S3_FOLDER = 'flowise-ai-lab/'

AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')

def create_backup(volume_path, backup_path):
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    backup_filename = f"volume_backup_{timestamp}.tar.gz"
    backup_filepath = os.path.join(backup_path, backup_filename)
    shutil.make_archive(backup_filepath.replace('.tar.gz', ''), 'gztar', volume_path)

    return backup_filepath

def upload_to_s3(file_path, bucket, prefix=''):
    s3_client = boto3.client('s3', aws_access_key_id=AWS_ACCESS_KEY_ID, aws_secret_access_key=AWS_SECRET_ACCESS_KEY)
    file_name = os.path.basename(file_path)
    s3_key = os.path.join(prefix, file_name)

    s3_client.upload_file(file_path, bucket, s3_key)
    print(f"Backup uploaded to s3://{bucket}/{s3_key}")

def main():
    if not os.path.exists(BACKUP_PATH):
        os.makedirs(BACKUP_PATH)

    backup_filepath = create_backup(VOLUME_PATH, BACKUP_PATH)
    print(f"Backup created at {backup_filepath}")
    upload_to_s3(backup_filepath, S3_BUCKET, S3_FOLDER)
    os.remove(backup_filepath)
    print(f"Local backup file {backup_filepath} removed")

if __name__ == "__main__":
    schedule.every().day.at("16:00").do(main)
    while True:
        schedule.run_pending()
        sleep(200)
