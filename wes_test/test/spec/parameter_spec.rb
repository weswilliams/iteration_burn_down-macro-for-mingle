require "rspec"
require "../../lib/wes_test"

describe "burn down parameter" do
  before do
    @parameters = {}
    @burn_down_macro = WesTest.new(@parameters, nil, nil)
  end

  subject { @burn_down_macro }

  describe "date accepted property" do
    subject { @burn_down_macro.date_accepted_property }

    context "when using default" do
      it { should == 'date_accepted' }
    end

    context "when setting as parameter" do
      before { @parameters['date_accepted'] = 'accepted_on' }
      it { should == 'accepted_on' }
    end

  end

  describe "field conversion" do
    subject { @burn_down_macro.parameter_to_field 'date_accepted' }
    it { should == 'Date Accepted'}
  end

end