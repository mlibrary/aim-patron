require "net/ldap"
module Services
  class << self
    def ldap
      @@ldap ||= init_ldap
    end

    def app_env
      ENV["APP_ENV"] || "development"
    end

    def ldap_host
      ENV["LDAP_HOST"]
    end

    def ldap_dn
      ENV["LDAP_DN"]
    end

    def ldap_username
      ENV["LDAP_USERNAME"]
    end

    def ldap_password
      ENV["LDAP_PASSWORD"]
    end

    private

    def init_ldap
      if app_env == "production"
        Net::LDAP.new(host: ldap_host, auth: {method: :simple, dn: ldap_dn, password: ldap_password}, port: 636, encryption: {method: :simple_tls})
      else
        Net::LDAP.new(host: ldap_host, auth: {method: :simple, username: ldap_username, password: ldap_password}, port: 636, encryption: {method: :simple_tls})
      end
    end
  end
end

S = Services
