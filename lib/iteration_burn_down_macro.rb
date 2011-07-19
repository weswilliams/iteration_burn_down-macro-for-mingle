require "date"
require "parameters"

module CustomMacro

  class IterationBurnDownMacro
    include CustomMacro, CustomMacro::Parameters

    MON = 1
    TUE = 2
    WED = 3
    THU = 4
    FRI = 5

    WEEKDAYS = [MON, TUE, WED, THU, FRI]

    def initialize(parameters, project, current_user)
      @project = project
      @current_user = current_user
      @parameters = Parameters::Parameters.new( parameters,
         'iteration' => lambda { @project.value_of_project_variable('Current Iteration') },
         'release' => lambda { @project.value_of_project_variable('Current Release') },
         'time_box' => 'iteration',
         'today' => Date.today,
         'chart_width' => 600,
         'chart_height' => 400,
         'ideal_line_color' => "00FF00",
         'burndown_line_color' => "FF0000")
   end

    def execute
      begin
        chart_url = 'https://chart.googleapis.com/chart?'
        chart_title = 'chtt=Iteration%20Burndown'
        date_range = iteration_date_range
        weekdays_x_axis = weekdays_for(date_range).collect { |day| "#{day.month}-#{day.day}" }.join('|')
        stories = story_info
        total_story_points = calculate_total_story_points stories
        chart_range = "chxr=1,0,#{total_story_points},#{y_axis_step(total_story_points)}"
        ideal_line_data = generate_idea_line_data(total_story_points, date_range)
        x_data = generate_x_data(date_range)
        burn_down_line = generate_burndown_line_data(total_story_points, story_info, date_range)

        <<-HTML
    h2. #{iteration_link} Burndown

    <img src='#{chart_url}cht=lxy&chs=#{chart_width_parameter}x#{chart_height_parameter}&chds=a&#{chart_title}&chls=1,6,6&chxt=x,y&#{chart_range}&chma=50,0,0,50&chdl=Ideal%20Line|Burndown&chco=#{ideal_line_color_parameter},#{burndown_line_color_parameter}&chd=t:#{x_data}|#{ideal_line_data}|#{x_data}|#{burn_down_line}&chxl=0:|#{weekdays_x_axis}|1:|'></img>
        HTML
      rescue Exception => e
        <<-ERROR
    h2. Iteration Burndown Error:

    "An Error occurred: #{e}"<br>
    #{e.backtrace.join("<br>")}
        ERROR
      end
    end

    def y_axis_step(total_story_points)
      step = (total_story_points/10.0).ceil
      step <=0 ? 1 : step
    end

    def generate_burndown_line_data(total_story_points, story_info, date_range)
      return '' if total_story_points == 0
      weekdays = weekdays_for(date_range)
      points_by_past_weekdays = {}
      weekdays.each { |weekday| points_by_past_weekdays[weekday] = total_story_points if weekday <= today_parameter }
      story_info.select { |story| story[date_accepted_parameter] }.each do |accepted_story|
        accepted_on = accepted_story[date_accepted_parameter]
        points = accepted_story[story_points_parameter] || 0
        points_by_past_weekdays.keys.select { |past_day| past_day >= accepted_on }.each do |accumulate_day|
          points_by_past_weekdays[accumulate_day] -= points.to_i
        end
      end
      points_by_past_weekdays.values.join(',')
    end

    def generate_x_data(date_range)
      (0...(weekdays_for(date_range).count)).to_a.join(',')
    end

    def generate_idea_line_data(total_story_points, date_range)
      return '' if total_story_points == 0
      number_of_weekdays = weekdays_for(date_range).count
      step = (total_story_points * 1.0) / (number_of_weekdays - 1)
      idea_data = []
      (0.0..total_story_points).step(step) { |value| idea_data << value }
      idea_data.reverse.join(',')
    end

    def calculate_total_story_points(stories)
      stories.inject(0) { |total, hash| hash[story_points_parameter] ? total + hash[story_points_parameter].to_i : total }
    end

    def story_info
      begin
        iteration_where = "Iteration = '#{iteration_name}'"
        iteration_where = "Iteration = #{iteration}" if iteration == 'THIS CARD'
        data_rows = @project.execute_mql(
            "SELECT '#{parameter_to_field(story_points_parameter)}', '#{date_accepted_field}' WHERE type is Story AND #{iteration_where}")
        data_rows.each { |hash| hash.update(hash) { |key, value| (key == date_accepted_parameter && value) ? Date.parse(value) : value } }
      rescue Exception => e
        raise "[error retrieving story info for iteration '#{iteration}': #{e}]"
      end
    end

    def iteration_date_range
      begin
        iteration_where = "Number = #{iteration_number}"
        iteration_where = "Number = #{iteration}.'Number'" if iteration == 'THIS CARD'
        data_rows = @project.execute_mql("SELECT 'Start Date', 'End Date' WHERE #{iteration_where}")
        raise "##{iteration} is not a valid iteration" if data_rows.empty?
        Date.parse(data_rows[0]['start_date'])..Date.parse(data_rows[0]['end_date'])
      rescue Exception => e
        raise "error getting data for iteration #{iteration}: #{e}"
      end
    end

    def weekdays_for(date_range)
      ((date_range.begin)..(date_range.end)).select { |day| WEEKDAYS.include? day.wday }
    end

    def iteration
      @parameters['iteration'] || @project.value_of_project_variable('Current Iteration')
    end

    def iteration_name
      match_data = /#\d+ (.*)/.match(iteration)
      if  match_data
        match_data[1]
      else
        'Unknown'
      end
    end

    def iteration_number
      match_data = /#(\d+).*/.match(iteration)
      if  match_data
        match_data[1].to_i
      else
        'Unknown'
      end
    end

    def iteration_link
      return "#{iteration_name} #{@project.identifier}/##{iteration_number}" if @parameters['project']
      iteration
    end

    def can_be_cached?
      false # if appropriate, switch to true once you move your macro to production
    end

  end

end
