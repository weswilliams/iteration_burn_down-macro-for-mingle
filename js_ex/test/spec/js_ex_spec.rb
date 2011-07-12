require "rspec"
require "date"
require "./lib/iteration_burn_down_macro"


describe "burn down query" do
  before do
    @macro = CustomMacro::JsEx.new(nil, nil, nil)
  end

  subject { @macro.execute }

  context "blah" do
    before do
    end
    it { should == 'blah' }
  end
end
