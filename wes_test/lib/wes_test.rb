class WesTest

  def initialize(parameters, project, current_user)
    @parameters = parameters
    @project = project
    @current_user = current_user
  end
    
  def execute
#    html = "h2. Iteration ##{parameters['current_iteration']} Burndown:"
#    @parameters.each {|key, value| html << "param: '#{key} = #{value}'<br>"}
    <<-HTML
    h2. Iteration ##{@parameters['current_iteration']} Burndown:

    <div id="burndown_chart" style="width: 600px; height: 400px"></div>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      MingleJavascript.register(function initialize() {
       alert('Test macro javascript');
      });
    </script>
    HTML
  end

#  $('burndown_chart').innerHTML = 'burn down div';
#  var drawChart = function() {
#    $('burndown_chart').innerHTML = 'burn down div';
#    //var data = new google.visualization.DataTable();
#    //data.addColumn('string', 'Day');
#    //data.addColumn('number', 'Ideal');
#    //data.addRow(["6/1/11", 6]);
#    //data.addRow(["6/2/11", 5]);
#    //data.addRow(["6/3/11", 4]);
#    //data.addRow(["6/4/11", 3]);
#    //data.addRow(["6/5/11", 2]);
#    //data.addRow(["6/6/11", 1]);
#    //data.addRow(["6/7/11", 0]);
#    // Create and draw the visualization.
#    //new google.visualization.LineChart(document.getElementById('burndown_chart')).
#    //  draw(data, {curveType: "function",
#    //          width: 600, height: 400,
#    //          vAxis: {maxValue: 8}});
#  };
#  google.load('visualization', '1', {'packages':['corechart']}
#  google.setOnLoadCallback(drawChart);
#  drawChart();


  def can_be_cached?
    false  # if appropriate, switch to true once you move your macro to production
  end

end

