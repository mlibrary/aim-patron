describe Name do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
  end
  subject do
    described_class.new(@patron)
  end
  xcontext "givenname, middle, and last name" do
    context "#first_name" do
      it "is a string" do
        expect(subject.first_name).to eq("Emily") 
      end
    end
    context "#middle_name" do
      it "is a string" do
        expect(subject.middle_name).to eq("O") 
      end
    end
    context "#last_name" do
      it "is a string" do
        expect(subject.last_name).to eq("Card") 
      end
    end
    context "#middle_name?" do
      it "is true" do 
        expect(subject.middle_name?).to eq(true) 
      end
    end
  end
  xcontext "no givenname, but existing displayname" do
    before(:each) do
      @patron.delete("givenname")
    end
    context "#first_name" do
      it "is a string" do
        expect(subject.first_name).to eq("Emily") 
      end
    end
    context "#middle_name" do
      it "is a string" do
        expect(subject.middle_name).to eq("O") 
      end
    end
    context "#last_name" do
      it "is a string" do
        expect(subject.last_name).to eq("Card") 
      end
    end
    context "#middle_name?" do
      it "is true" do 
        expect(subject.middle_name?).to eq(true) 
      end
    end
  end
  xcontext "no umichdisplaysn, but existing displayname" do
    before(:each) do
      @patron.delete("umichdisplaysn")
      @patron["givenname"][0] = "EmilyGivenName"
    end
    context "#first_name" do
      it "is a string" do
        expect(subject.first_name).to eq("EmilyGivenName") 
      end
    end
    context "#middle_name" do
      it "is a string" do
        expect(subject.middle_name).to eq("O") 
      end
    end
    context "#last_name" do
      it "is a string" do
        expect(subject.last_name).to eq("Card") 
      end
    end
    context "#middle_name?" do
      it "is true" do 
        expect(subject.middle_name?).to eq(true) 
      end
    end
  end
  xcontext "no umichdisplaysn or givenname, but existing displayname" do
    before(:each) do
      @patron.delete("umichdisplaysn")
      @patron.delete("givenname")
    end
    context "#first_name" do
      it "is a string" do
        expect(subject.first_name).to eq("Emily") 
      end
    end
    context "#middle_name" do
      it "is a string" do
        expect(subject.middle_name).to eq("O") 
      end
    end
    context "#last_name" do
      it "is a string" do
        expect(subject.last_name).to eq("Card") 
      end
    end
    context "#middle_name?" do
      it "is true" do 
        expect(subject.middle_name?).to eq(true) 
      end
    end
  end
  xcontext "no umichdisplaymiddle, but existing displayname" do
    before(:each) do
      @patron.delete("umichdisplaymiddle")
      @patron["displayname"][0] = "Emily O Card"
    end
    context "#first_name" do
      it "is a string" do
        expect(subject.first_name).to eq("Emily") 
      end
    end
    context "#middle_name" do
      it "is a string" do
        expect(subject.middle_name).to eq("O") 
      end
    end
    context "#last_name" do
      it "is a string" do
        expect(subject.last_name).to eq("Card") 
      end
    end
    context "#middle_name?" do
      it "is true" do 
        expect(subject.middle_name?).to eq(true) 
      end
    end
  end
  xcontext "no umichdisplaymiddle, and displayname doesn't have a middle name" do
    before(:each) do
      @patron.delete("umichdisplaymiddle")
    end
    context "#first_name" do
      it "is a string" do
        expect(subject.first_name).to eq("Emily") 
      end
    end
    context "#middle_name" do
      it "is a string" do
        expect(subject.middle_name).to be_nil
      end
    end
    context "#last_name" do
      it "is a string" do
        expect(subject.last_name).to eq("Card") 
      end
    end
    context "#middle_name?" do
      it "is false" do 
        expect(subject.middle_name?).to eq(false) 
      end
    end
  end
end
