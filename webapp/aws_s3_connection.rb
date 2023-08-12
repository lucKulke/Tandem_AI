class AwsS3
  attr_reader :bucket_name
  
  def initialize(bucket_name: '', region: 'eu-north-1', access_key: '', secret_key: '' )
    @bucket_name = bucket_name
    Aws.config.update(
      region: region,
      credentials: Aws::Credentials.new(access_key, secret_key)
    )
  end

  def upload_audio_file(file_name)
    
    file_path = "./public/audio_files/#{file_name}"
    file_content = File.read(file_path)
    begin
      s3_client = Aws::S3::Client.new
      s3_client.put_object(
        bucket: bucket_name,
        key: "upload_ai/#{file_name}",
        body: file_content
        )
    rescue Aws::S3::Errors::NetworkError, Timeout::Error => e
    
    end
  
  end

  def get_presigned_url_s3(file_name, folder)
    s3 = Aws::S3::Resource.new

    obj = s3.bucket(bucket_name).object("#{folder}/#{file_name}")
    
    url = obj.presigned_url(:put, expires_in: 3600) # URL expires in 1 hour
    
    { url: url, filename: file_name }
  end

end