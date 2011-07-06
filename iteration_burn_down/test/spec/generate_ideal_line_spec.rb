require "rspec"
require "./lib/iteration_burn_down_macro"

describe "generate ideal line data" do
  before do
    @burn_down_macro = IterationBurnDownMacro.new({}, nil, nil)
  end

  subject { @burn_down_macro.generate_idea_line_data 4, (Date.parse('2011-06-01')..(Date.parse('2011-06-07'))) }
  context "ideal points completed each day excluding weekends" do
    it { should == "4.0,3.0,2.0,1.0,0.0" }
  end

end
