require "rspec"
require "../../lib/iteration_burn_down_macro"

describe "generate x data" do
  before do
    @burn_down_macro = IterationBurnDownMacro.new({}, nil, nil)
  end

  subject { @burn_down_macro.generate_x_data (Date.parse('2011-06-01')..(Date.parse('2011-06-07'))) }
  context "0 - n day values excluding weekends" do
    it { should == "0,1,2,3,4" }
  end

end
