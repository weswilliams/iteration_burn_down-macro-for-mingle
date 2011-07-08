require "rspec"
require "./lib/release_metrics"

describe "remaining stories" do
  before do
    @current_release = [ {'end_date' => '2011-07-05' } ]
    @parameters = {}
    @project = double('project',
                      :value_of_project_variable => '#1 Release 1',
                      :execute_mql => @current_release)
    @macro = CustomMacro::ReleaseMetrics.new(@parameters, @project, nil)
  end

  context "retrieve current release end date" do
    before do
      @project.should_receive(:execute_mql).with("SELECT 'End Date' WHERE Number = 1")
    end

    subject { @macro.current_release }
    it { should == @current_release[0] }
  end

  context "#release_end_date" do
    subject { @macro.release_end_date @current_release[0] }
    it { should == '2011-07-05' }
  end
end
