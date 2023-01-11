require_relative "./process_ldap"
# require sftp

FILENAME = "/app/scratch/output.xml"
ZIPPED_FILENAME = "/app/scratch/output.zip"

File.open(FILENAME, "w") do |f|
  ProcessLdapDaily.new(date: "2023-01-11", output: f).process
end

system("zip", ZIPPED_FILENAME, FILENAME)
# sftp ZIPPED_FILENAME
