require "rspec"
require "../../lib/iteration_burn_down_macro"

describe "calculate total story points" do
  before do
    @burn_down_macro = IterationBurnDownMacro.new({}, nil, nil)
    @stories = [
        {'story_points' => 5},
        {'story_points' => 3}
    ]
  end

  subject { @burn_down_macro.calculate_total_story_points @stories }
  it { should == 8 }

end
