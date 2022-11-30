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
