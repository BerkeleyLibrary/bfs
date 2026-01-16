module Mailer 
require 'mail'
require_relative 'logging'
include Logging
require_relative 'envs'


def self.send_message(subject,body,attachments=nil)
  mail_secrets = ["MAIL_PASSWORD","MAIL_USERNAME","BFS_EMAILS"]
  mail_envs = Envs::get_envs(mail_secrets)

  if mail_envs.nil? 
    logger.info "Going to skip sending email since environment variables are not set, MAIL_USERNAME,MAIL_PASSWORD, and BFS_EMAILS"
    return
  end

  if ENV["SKIP_EMAILS"]
    logger.info "Going to skip sending email since environment variable SKIP_EMAIL is set"
    return
  end

  logger.info "Going to send email"

  from_email =  "lib-noreply@berkeley.edu"

  options = {:address             => "smtp.gmail.com",
            :port                 => 465,
            :user_name            => mail_envs["MAIL_USERNAME"],
            :password             => mail_envs["MAIL_PASSWORD"], 
            :authentication       => 'plain',
            :tls                  => true,
            :enable_starttls_auto => true,
            :return_response => true
  }

  
  Mail.defaults do
    delivery_method :smtp, options
  end

  mail_envs["BFS_EMAILS"].split(/,/).each do |to_email|
    begin
      Mail.deliver do
        to to_email.gsub(/\n/,'')
        from from_email 
        subject subject 
        body body 
        attachments.each do |attachment|
      	  add_file attachment if File.file?(attachment) 
        end 
      end
      logger.info "Email sent"
    rescue StandardError => e
        logger.info "Error sending email: #{e}"
    end 
  end
 
  #sleeping for 2 seconds so emails don't get flagged for spamming 
  sleep 2
end


end
