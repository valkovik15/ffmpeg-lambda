require 'json'
require 'digest'
require 'aws-sdk-s3'
require 'net/http'
require 'net/https'
require 'securerandom'

def convert(event:, context:)
    record = event['Records'].first
    file_name = record.dig('s3', 'object', 'key')
    return unless record['s3']
    client = Aws::S3::Client.new(region: record['awsRegion'])
    s3 = Aws::S3::Resource.new(client: client)
    bucket_name = record.dig('s3', 'bucket', 'name')
    local_path = "/tmp/#{file_name}"
    return if client.head_object(bucket: bucket_name, key: file_name).to_h[:content_type]=='video/mp4'
    f = File.new(local_path, 'w+')
    return unless client.get_object(response_target: local_path, bucket: bucket_name, key: file_name)
    mp4_key = "#{SecureRandom.hex}#{Time.now.to_i}"
    mp4_filename = "/tmp/#{mp4_key}"
    `/opt/ffmpeg/ffmpeg -i #{local_path} -movflags +faststart -c:v libx264 -pix_fmt yuv420p -profile:v main -level 3.0 -b:v 2.5M -c:a aac -b:a 128k -r 30 #{mp4_filename}.mp4`
    client.put_object(bucket: bucket_name, key: mp4_key, body: File.open("#{mp4_filename}.mp4"), content_type: 'video/mp4')
    File.open("#{mp4_filename}.mp4") { |file|
        logs = { 
            content_md5: Digest::MD5.file(file).base64digest,
            byte_size: File.size(file).to_s,
            key: mp4_key,
            content_type: 'video/mp4',
            webm_key: file_name
            }
        uri = URI.parse(ENV['API_ENDPOINT'])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        header = {'Content-Type': 'text/json'}
        request = Net::HTTP::Post.new(uri.request_uri, header)
        request.set_form_data logs
        resp = http.request(request)
    }
    File.delete(f.path) if File.exist?(f.path)
    File.delete("#{mp4_filename}.mp4") if File.exist?("#{mp4_filename}.mp4")
  {
    statusCode: 200,
    body: {
      message: 'The function executed successfully!',
      input: event
    }.to_json
  }
end

    
