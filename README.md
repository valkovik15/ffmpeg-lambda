# ffmpeg-lambda
Ruby AWS Lambda for converting WEBM to MP4

### Setup
1. Install serverless
```
npm install -g serverless #or
curl -o- -L https://slss.io/install | bash
```
2. Configure your AWS account
```
serverless config credentials --provider aws --key YOUR_KEY --secret YOUR_SECRET
```
3. Update custom section of serverless.yml file: set bucket, its region and replace ngrok host with the webapp host, max execution time
4. Deploy the lambda
```
sls deploy
```
