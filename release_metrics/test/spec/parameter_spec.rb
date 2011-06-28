require "rspec"
require "../../lib/release_metrics"

describe "burn down parameter" do
  before do
    @parameters = {}
    @project = double('project', :value_of_project_variable => '#3 Iteration 1')
    @burn_down_macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro }

  describe "Current Iteration project property" do
    subject { @burn_down_macro.iteration }
    it { should == '#3 Iteration 1' }
  end

  describe "iteration" do
    subject { @burn_down_macro.iteration_number }
    it { should == 3 }
  end

  describe "iteration when overriding with parameter" do
    before { @parameters['iteration'] = '#4 Iteration 2' }

    context "iteration number" do
      subject { @burn_down_macro.iteration_number }
      it { should == 4 }
    end

    context "iteration name" do
      subject { @burn_down_macro.iteration_name }
      it { should == 'Iteration 2' }
    end
  end

  describe "iteration_name" do
    subject { @burn_down_macro.iteration_name }
    it { should == 'Iteration 1' }
  end

#  describe "date accepted property" do
#    subject { @burn_down_macro.date_accepted_property }
#
#    context "when using default" do
#      it { should == 'date_accepted' }
#    end
#
#    context "when setting as parameter" do
#      before { @parameters['date_accepted'] = 'accepted_on' }
#      it { should == 'accepted_on' }
#    end
#
#  end
#
#  describe "date accepted property" do
#    subject { @burn_down_macro.estimate_property }
#
#    context "when using default" do
#      it { should == 'story_points' }
#    end
#
#    context "when setting as parameter" do
#      before { @parameters['story_points'] = 'planning_estimate' }
#      it { should == 'planning_estimate' }
#    end
#
#  end

  describe "field conversion" do
    subject { @burn_down_macro.parameter_to_field 'date_accepted' }
    it { should == 'Date Accepted' }
  end

end