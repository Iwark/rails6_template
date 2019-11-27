if Rails.application.credentials.aws_access_key_id.present?
  Aws.config.update({
    credentials: Aws::Credentials.new(
      Rails.application.credentials.aws_access_key_id, 
      Rails.application.credentials.aws_secret_access_key),
    region: "ap-northeast-1"
  })

  ActionMailer::Base.add_delivery_method :ses,
    AWS::SES::Base,
    access_key_id: Rails.application.credentials.aws_access_key_id,
    secret_access_key: Rails.application.credentials.aws_secret_access_key,
    server: 'email.us-west-2.amazonaws.com'
end