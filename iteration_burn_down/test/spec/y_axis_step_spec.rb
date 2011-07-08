require "rspec"
require "./lib/iteration_burn_down_macro"

describe "steps between y grid values" do
  describe "limit y axis to 10 major points in grid" do
    before do
      @burn_down_macro = CustomMacro::IterationBurnDownMacro.new({}, nil, nil)
    end

    context "when total story points is 10" do
      subject { @burn_down_macro.y_axis_step 10 }
      it { should == 1 }
    end

    context "when total story points is < 10" do
      subject { @burn_down_macro.y_axis_step 5 }
      it { should == 1 }
    end

    context "when total story points is > 10" do
      subject { @burn_down_macro.y_axis_step 11 }
      it { should == 2 }
    end

    context "when total story points is < 21" do
      subject { @burn_down_macro.y_axis_step 20 }
      it { should == 2 }
    end

    context "when total story points is > 20" do
      subject { @burn_down_macro.y_axis_step 21 }
      it { should == 3 }
    end

  end
end