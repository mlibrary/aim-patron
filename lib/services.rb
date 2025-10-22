require "net/ldap"
module Services
  class << self
    def project_root
      @@project_root ||= File.absolute_path(File.join(__dir__, ".."))
    end

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

    def ldap_password
      ENV["LDAP_PASSWORD"]
    end

    def output_directory
      @@output_directory ||= ENV["OUTPUT_DIRECTORY"] || File.join(project_root, "output")
    end

    private

    def init_ldap
      Net::LDAP.new(host: ldap_host, auth: {method: :simple, dn: ldap_dn, password: ldap_password}, port: 636, encryption: {method: :simple_tls})
    end
  end
end

S = Services
