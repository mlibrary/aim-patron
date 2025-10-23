require "net/ldap"
require "semantic_logger"

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

    def log_stream
      @@log_stream ||= begin
        $stdout.sync = true
        $stdout
      end
    end

    def log_level
      @@log_level ||= ENV["DEBUG"] ? :debug : :info
    end

    def logger
      @@logger ||= SemanticLogger["patron_load"]
    end

    private

    def init_ldap
      Net::LDAP.new(host: ldap_host, auth: {method: :simple, dn: ldap_dn, password: ldap_password}, port: 636, encryption: {method: :simple_tls})
    end
  end
end

S = Services

SemanticLogger.default_level = S.log_level

class ProductionFormatter < SemanticLogger::Formatters::Json
  # Leave out the pid
  def pid
  end

  # Leave out the timestamp
  def time
  end

  # Leave out environment
  def environment
  end

  # Leave out application (This would be Semantic Logger, which isn't helpful)
  def application
  end
end

if S.app_env != "test"
  if $stdin.tty?
    SemanticLogger.add_appender(io: S.log_stream, formatter: :color)
  else
    SemanticLogger.add_appender(io: S.log_stream, formatter: ProductionFormatter.new)
  end
end
