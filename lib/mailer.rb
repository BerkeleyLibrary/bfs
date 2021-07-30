module Mailer 
require 'mail'
require_relative 'Logging'
include Logging


def self.get_envs()
  envs = {}

  ["MAIL_PASSWORD","MAIL_USERNAME","BFS_EMAILS"].each do |env| 
    if ENV[env]
      envs[env] = ENV[env]      
    else 
      logger.info "Environment variable not set for #{env}, Can't send email"
      return nil
    end
  end

  if ENV["SKIP_EMAIL"]
    envs["SKIP_EMAIL"] = ENV["SKIP_EMAIL"]
  end

  return envs 
end


def self.send_message(subject,body,attachments=nil)

  envs = get_envs
  if envs.nil? 
    logger.info "Going to skip sending email since environment variables are not set, MAIL_USERNAME,MAIL_PASSWORD, and BFS_EMAILS"
    return
  end
  if envs["SKIP_EMAIL"]
    logger.info "Going to skip sending email since environment variable SKIP_EMAIL is set"
    return
  end

  logger.info "Going to send email"

  from_email =  "lib-noreply@berkeley.edu"

  options = {:address             => "smtp.gmail.com",
            :port                 => 587,
            :user_name            => envs["MAIL_USERNAME"],
            :password             => envs["MAIL_PASSWORD"], 
            :authentication       => 'plain',
            :enable_starttls_auto => true,
            :return_response => true
  }

  
  Mail.defaults do
    delivery_method :smtp, options
  end

  envs["BFS_EMAILS"].split(/,/).each do |to_email|
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
    rescue StandardError => e
        logger.info "Error sending email: #{e}"
    end 
  end

  logger.info "Email sent"
 
  #sleeping for 2 seconds so emails don't get flagged for spamming 
  sleep 2
end


end
