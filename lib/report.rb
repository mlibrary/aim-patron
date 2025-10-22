class Report
  def self.open(file_base, &block)
    File.open("#{file_base}.tsv", "w") do |fh|
      report = Report.new(fh)
      block.call(report)
    end
  end

  def initialize(fh)
    @fh = fh
  end

  def load(patron)
    @fh.write "LOAD\t#{patron.umid.value}\t#{patron.uniqname}\n"
  end

  def skip(patron)
    @fh.write "SKIP\t#{patron.umid.value}\t#{patron.uniqname}\t#{patron.exclude_reasons.join(";")}\n"
  end
end
