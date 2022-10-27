describe "Patron Load Schedule Config Validation" do
  it "the config file has valid lines" do
    CSV.foreach("./config/patron_load_schedule.tsv", headers: true, col_sep: "\t") do |row|
      expect { Date.parse(row["Update Date"]) }.not_to raise_error,
        "Update date #{row["Update Date"]} in row: #{row} is not a valid date"

      expect { Date.parse(row["Expiry Date"]) }.not_to raise_error,
        "Expiry date #{row["Expiry Date"]} in row: #{row} is not a valid date"

      row["Term"].split(", ").each do |term|
        expect(term.match?(/^[[:alpha:]]+[[:digit:]][[:digit:]]$/)).to eq(true),
          "expected #{term} to be look like /^[[:alpha:]]+[[:digit:]][[:digit:]]$/; for row: #{row}"
        expect(["W", "SP", "SS", "SU", "F"].include?(/[[:alpha:]]+/.match(term).to_s)).to eq(true),
          "expect the letters part of #{term} in row #{row} to be one of: W,SP,SS,SU,F"
      end
    end
  end
end
