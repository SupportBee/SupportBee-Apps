module Compose
  module ActionHandler
    def button
      mail_from = settings.from
      mail_to = payload.overlay.to
      mail_subject = payload.overlay.subject
      mail_body = payload.overlay.body
      ssl = settings.ssl == '1' ? true : false

      return [500, 'Invalid From Address'] unless valid_email?(mail_from)
      return [500, 'Invalid To Address'] unless valid_email?(payload.overlay.to)

      mail = Mail.new do
        from mail_from
        to mail_to
        subject mail_subject
        body mail_body
      end

      mail.delivery_method(:smtp, {
        address: settings.server,
        port: settings.server_port.to_i,
        user_name: settings.username,
        password: settings.password,
        enable_starttls_auto: true,
        ssl: ssl
      })

      begin
        mail.deliver
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Message sent to #{mail_to}"]
    end
  end
end

module Compose
  class Base < SupportBeeApp::Base
    string :server, :required => true, :label => "SMTP Server Address"
    string :server_port, :required => true, :label => "SMTP Server Port"
    string :username, :required => true, :label => "Username"
    password :password, :required => true, :label => "Password"
    string :from, :required => true, :label => "From Address"
    boolean :ssl, :default => true, :label => "SSL"

    white_list :server, :server_port, :ssl

    private

    def email_regex(options={:strict_mode => false})
      name_validation = options[:strict_mode] ? "-a-z0-9+._" : "^@\\s"
      /^\s*([#{name_validation}]{1,64})@((?:[-a-z0-9]+\.)+[a-z]{2,})\s*$/i
    end

    def valid_email?(email)
      not((email_regex =~ email).nil?) 
    end
  end
end
