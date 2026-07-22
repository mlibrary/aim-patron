describe CurrentSchedule do
  def expect_expiry_date(given, expected)
    today = Date.parse(given)
    expect(described_class.new(today).expiry_date).to eq(Date.parse(expected))
  end

  def expect_update_date(given, expected)
    today = Date.parse(given)
    expect(described_class.new(today).update_date).to eq(Date.parse(expected))
  end
  context "#includable_term?" do
    it "is true when the term given should be included" do
      today = Date.parse("2026-07-22")
      schedule = described_class.new(today)
      expect(schedule.includable_term?("F26")).to eq(true)
      expect(schedule.includable_term?("SU26")).to eq(true)
      expect(schedule.includable_term?("SS26")).to eq(true)
    end
    it "is false when the term given should not be included" do
      today = Date.parse("2026-07-22")
      schedule = described_class.new(today)
      expect(schedule.includable_term?("W26")).to eq(false)
      expect(schedule.includable_term?("SP26")).to eq(false)
      expect(schedule.includable_term?("W27")).to eq(false)
    end
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
  context "#terms" do
    it "has expected terms for given date" do
      expect(described_class.new(Date.parse("2026-04-04")).terms).to contain_exactly("SP26", "SS26", "SU26", "F26")
    end
  end
end

describe CurrentSchedule::Winter do
  it "has expected text" do
    expect(described_class.new(2026).text).to eq("W26")
    expect(described_class.new(2027).text).to eq("W27")
  end

  context "#in_range" do
    it "is in range for the second friday of January" do
      expect(described_class.new(2026).in_range(Date.parse("2026-01-09"))).to eq(true)
    end
    it "is in range for the day before the first friday in April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-02"))).to eq(true)
    end
    it "is out of range for the day before the second friday in January" do
      expect(described_class.new(2026).in_range(Date.parse("2026-01-08"))).to eq(false)
    end
    it "is out of range for the first friday in January" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-03"))).to eq(false)
    end
  end
end
describe CurrentSchedule::Spring do
  it "has expected text" do
    expect(described_class.new(2026).text).to eq("SP26")
    expect(described_class.new(2027).text).to eq("SP27")
  end

  context "#in_range" do
    it "is in range for the first friday of April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-03"))).to eq(true)
    end
    it "is in range for the day before the first friday in July" do
      expect(described_class.new(2026).in_range(Date.parse("2026-07-02"))).to eq(true)
    end
    it "is out of range for the day before the first friday in April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-02"))).to eq(false)
    end
    it "is out of range for the first friday in July" do
      expect(described_class.new(2026).in_range(Date.parse("2026-07-03"))).to eq(false)
    end
  end
end
describe CurrentSchedule::Summer do
  it "has expected text" do
    expect(described_class.new(2026).text).to eq("SU26")
    expect(described_class.new(2027).text).to eq("SU27")
  end

  context "#in_range" do
    it "is in range for the first friday of April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-03"))).to eq(true)
    end
    it "is in range for the day before the first friday in August" do
      expect(described_class.new(2026).in_range(Date.parse("2026-08-06"))).to eq(true)
    end
    it "is out of range for the day before the first friday in April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-02"))).to eq(false)
    end
    it "is out of range for the first friday in August" do
      expect(described_class.new(2026).in_range(Date.parse("2026-08-07"))).to eq(false)
    end
  end
end
describe CurrentSchedule::SpringSummer do
  it "has expected text" do
    expect(described_class.new(2026).text).to eq("SS26")
    expect(described_class.new(2027).text).to eq("SS27")
  end
  context "#in_range" do
    it "is in range for the first friday of April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-03"))).to eq(true)
    end
    it "is in range for the day before the first friday in August" do
      expect(described_class.new(2026).in_range(Date.parse("2026-08-06"))).to eq(true)
    end
    it "is out of range for the day before the first friday in April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-02"))).to eq(false)
    end
    it "is out of range for the first friday in August" do
      expect(described_class.new(2026).in_range(Date.parse("2026-08-07"))).to eq(false)
    end
  end
end
describe CurrentSchedule::Fall do
  it "has expected text" do
    expect(described_class.new(2026).text).to eq("F26")
    expect(described_class.new(2027).text).to eq("F27")
  end

  context "#in_range" do
    it "is in range for the first friday of April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-03"))).to eq(true)
    end
    it "is in range for the day before the second friday in January" do
      expect(described_class.new(2026).in_range(Date.parse("2027-01-07"))).to eq(true)
    end
    it "is out of range for the day before the first friday in April" do
      expect(described_class.new(2026).in_range(Date.parse("2026-04-02"))).to eq(false)
    end
    it "is out of range for the second friday in January" do
      expect(described_class.new(2026).in_range(Date.parse("2027-01-08"))).to eq(false)
    end
  end
end
