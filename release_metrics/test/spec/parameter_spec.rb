require "rspec"
require "../../lib/release_metrics"

describe "release parameter" do
  before do
    @parameters = {}
    @project = double('project', :value_of_project_variable => '#1 Release 1')
    @burn_down_macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro }

  describe "Current Release project property" do
    subject { @burn_down_macro.release }
    it { should == '#1 Release 1' }
  end

  describe "current release number" do
    subject { @burn_down_macro.release_number }
    it { should == 1 }
  end

  describe "release_name" do
    subject { @burn_down_macro.release_name }
    it { should == 'Release 1' }
  end

  describe "Release when overriding with parameter" do
    before { @parameters['release'] = '#4 Release 2' }

    context "release number" do
      subject { @burn_down_macro.release_number }
      it { should == 4 }
    end

    context "release name" do
      subject { @burn_down_macro.release_name }
      it { should == 'Release 2' }
    end
  end

  describe "field conversion" do
    subject { @burn_down_macro.parameter_to_field 'date_accepted' }
    it { should == 'Date Accepted' }
  end

end


describe "iteration parameter" do
  before do
    @parameters = {}
    @project = double('project', :value_of_project_variable => '#3 Iteration 5')
    @burn_down_macro = ReleaseMetrics.new(@parameters, @project, nil)
  end

  subject { @burn_down_macro.iteration }
  it { should == '#3 Iteration 5' }
end