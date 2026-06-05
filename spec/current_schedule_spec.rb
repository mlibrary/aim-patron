describe CurrentSchedule do
  def make_csv_string(array)
    CSV.generate do |csv|
      csv << array.first.keys # adds the attributes name on the first line
      array.each do |hash|
        csv << hash.values
      end
    end
  end
  before(:each) do
    @params = {
      config: CSV.parse(make_csv_string([
        {
          "Update Date" => "2022-01-08",
          "Term" => "W22",
          "Expiry Date" => "2022-04-30"
        },
        {
          "Update Date" => "2022-04-01",
          "Term" => "SP22, SS22, SU22, F22",
          "Expiry Date" => "2022-08-26"
        },
        {
          "Update Date" => "2022-05-06",
          "Term" => "SP22, SS22, SU22, F22",
          "Expiry Date" => "2022-08-30"
        }
      ]), headers: true),
      today: Date.parse("2022-01-10")
    }
  end
  subject do
    described_class.new(**@params)
  end
  context "#default_expiry_date" do
    it "choose first matching date" do
      expect(subject.default_expiry_date).to eq(Date.parse("2022-04-30"))
    end
    it "will go to a later date if the the first one is too early" do
      @params[:today] = Date.parse("2022-04-02")
      expect(subject.default_expiry_date).to eq(Date.parse("2022-08-26"))
    end
    it "will choose the last one if the update date is later than the last item" do
      @params[:today] = Date.parse("2022-09-02")
      expect(subject.default_expiry_date).to eq(Date.parse("2022-08-30"))
    end
  end
  context "#includable_term?" do
    it "handles a single matching term in the config" do
      expect(subject.includable_term?("W22")).to eq(true)
    end
    it "handles a single non-matching term in the config" do
      expect(subject.includable_term?("F22")).to eq(false)
    end
    it "handles case of a match among multiple terms" do
      @params[:today] = Date.parse("2022-04-02")
      expect(subject.includable_term?("F22")).to eq(true)
    end
    it "handles case of a non-match among multiple terms" do
      @params[:today] = Date.parse("2022-04-02")
      expect(subject.includable_term?("W22")).to eq(false)
    end
  end
end

describe NewCurrentSchedule do
  def expect_expiry_date(given, expected)
    today = Date.parse(given)
    expect(described_class.new(today).expiry_date).to eq(Date.parse(expected))
  end

  def expect_update_date(given, expected)
    today = Date.parse(given)
    expect(described_class.new(today).update_date).to eq(Date.parse(expected))
  end
  context "#expiry_date" do
    it "works for a basic example" do
      expect_expiry_date("2025-11-26", "2026-01-04")
    end
    it "handles May expiry dates" do
      expect_expiry_date("2025-12-11", "2026-01-04")
      # December update dates should be First Sunday in May
      expect_expiry_date("2025-12-12", "2026-05-03")
      expect_expiry_date("2026-12-11", "2027-05-02")
    end

    it "handles August expiry dates" do
      # April update dates should return last Sunday in August
      expect_expiry_date("2025-04-04", "2025-08-31")
      expect_expiry_date("2026-04-03", "2026-08-30")
      expect_expiry_date("2030-04-07", "2030-08-25")
    end

    it "handles Jaunary expiry dates" do
      # August update dates should return first Sunday in Jaunary of next year
      expect_expiry_date("2025-08-01", "2026-01-04")
      expect_expiry_date("2026-08-07", "2027-01-03")
    end
  end
  context "#update_date" do
    it "handles when today is in the same month" do
      # April before the April update date
      expect_update_date("2025-04-01", "2024-12-13")

      # April after the April update date
      expect_update_date("2025-04-10", "2025-04-04")

      # April on the April update date
      expect_update_date("2025-04-04", "2025-04-04")

      # August after the august update date
      expect_update_date("2025-08-10", "2025-08-01")

      # December bfore the december update date
      expect_update_date("2025-12-11", "2025-08-01")

      # Deceumber on the update date
      expect_update_date("2025-12-12", "2025-12-12")
    end
  end
end
