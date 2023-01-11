require "byebug"

require_relative "./process_ldap"
uniqname = ARGV[0]
ProcessLdapOneUser.new(uniqname: uniqname).process
