require "rspec"
require "../../lib/release_metrics"

describe "release parameter" do
  before do
    @parameters = {}
    @project = double('project', :value_of_project_variable => '#1 Release 1')
    @macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro }

  describe "Current Release project property" do
    subject { @macro.release_parameter }
    it { should == '#1 Release 1' }
  end

  describe "current release number" do
    subject { @macro.release_number }
    it { should == 1 }
  end

  describe "release_name" do
    subject { @macro.release_name }
    it { should == 'Release 1' }
  end

  describe "Release when overriding with parameter" do
    before { @parameters['release'] = '#4 Release 2' }

    context "release number" do
      subject { @macro.release_number }
      it { should == 4 }
    end

    context "release name" do
      subject { @macro.release_name }
      it { should == 'Release 2' }
    end
  end

  describe "field conversion" do
    subject { @macro.parameter_to_field 'date_accepted' }
    it { should == 'Date Accepted' }
  end

end

describe "story points" do
  before do
    @parameters = {'story_points' => 'estimate_field'}
    @project = double('project', :value_of_project_variable => '#3 Iteration 5')
    @macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  context "parameter" do
    subject { @macro.story_points_parameter }
    it { should == 'estimate_field' }
  end

  context "field" do
    subject { @macro.story_points_field }
    it { should == 'Estimate Field' }
  end

  context "field" do
    before do
      @parameters = {}
      @project = double('project', :value_of_project_variable => '#3 Iteration 5')
      @macro = ReleaseMetrics.new(@parameters, @project, nil)
    end
    subject { @macro.story_points_field }
    it { should == 'Story Points' }
  end
end

describe "iteration parameter" do
  before do
    @parameters = {}
    @project = double('project', :value_of_project_variable => '#3 Iteration 5')
    @macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  context "#iteration_parameter" do
    subject { @macro.iteration_parameter }
    it { should == '#3 Iteration 5' }
  end

end