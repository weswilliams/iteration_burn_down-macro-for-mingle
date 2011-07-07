require "date"

class ReleaseMetrics
  MON = 1
  TUE = 2
  WED = 3
  THU = 4
  FRI = 5

  WEEKDAYS = [MON, TUE, WED, THU, FRI]

  def initialize(parameters, project, current_user)
    @parameters = parameters
    @project = project
    @current_user = current_user
    @parameter_defaults = Hash.new { |h, k| h[k]=k }
    @parameter_defaults['iteration'] = lambda { @project.value_of_project_variable('Current Iteration') }
    @parameter_defaults['release'] = lambda { @project.value_of_project_variable('Current Release') }
    @parameter_defaults['time_box'] = 'iteration'
  end

  def execute
    begin
      release = current_release
      release_end = release_end_date release
      iterations = completed_iterations

      average_velocity = average_velocity last_3_iterations(iterations)
      all_iter_velocity = average_velocity iterations
      best_velocity = best_velocity_for iterations
      worst_velocity = worst_velocity_for iterations

      completed_stories = stories iterations, false
      completed_story_points = story_points_for completed_stories
      remaining_stories = stories iterations
      remaining_story_points = story_points_for remaining_stories
      last_end_date = iterations.length == 0 ? Date.today : last_iteration_end_date(iterations[0])
      iter_length = iterations.length == 0 ? 7 : iteration_length_in_days(iterations[0])

      remaining_iters_for_avg = remaining_iterations(average_velocity, remaining_story_points)
      remaining_iter_for_all_velocity = remaining_iterations(all_iter_velocity, remaining_story_points)
      remaining_iters_for_best = remaining_iterations(best_velocity, remaining_story_points)
      remaining_iters_for_worst = remaining_iterations(worst_velocity, remaining_story_points)

      avg_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iters_for_avg
      all_avg_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iter_for_all_velocity
      best_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iters_for_best
      worst_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iters_for_worst

      empty_column_header = "%{color:#EEEEEE}-%"
      empty_column = "%{color:white}-%"

      if mini_parameter.downcase == 'yes'

        <<-HTML
      |_. Scheduled End Date | #{release_end} |_. #{empty_column_header} |_. Estimated Completion <br> of #{card_link release_parameter} |_. Required <br> Iterations |_. Calculated Development End Date <br> Based on #{iter_length} Day Iterations |
      |_. Completed Story Points | #{completed_story_points} |_. #{empty_column_header}  | Average velocity of <br> last 3 iterations (#{"%.2f" % average_velocity}) | #{remaining_iters_for_avg} | #{avg_end_date} |
      |_. Remaining Story Points | #{remaining_story_points} |_. #{empty_column_header}  |Average velocity of <br> all iterations (#{"%.2f" % all_iter_velocity}) | #{remaining_iter_for_all_velocity} | #{all_avg_end_date} |
        HTML

      else
        <<-HTML
      h2. Metrics for #{card_link release_parameter}

      * Scheduled End Date is #{release_end}

      |_. Current Iteration | #{card_link iteration_parameter} |_. #{empty_column_header} |_. Estimated Completion <br> of #{card_link release_parameter} <br> Based on ... |_. Required <br> Iterations |_. Calculated Development End Date <br> Based on #{iter_length} Day Iterations |
      |_. Average Velocity <br> (last 3 iterations) | #{"%.2f" % average_velocity} |_. #{empty_column_header}  | Average velocity of <br> last 3 iterations (#{"%.2f" % average_velocity}) | #{remaining_iters_for_avg} | #{avg_end_date} |
      |_. Completed Iterations | #{iterations.length} |_. #{empty_column_header}  |Average velocity of <br> all iterations (#{"%.2f" % all_iter_velocity}) | #{remaining_iter_for_all_velocity} | #{all_avg_end_date} |
      |_. Completed Story Points | #{completed_story_points} |_. #{empty_column_header}  | Best velocity (#{best_velocity}) | #{remaining_iters_for_best} | #{best_end_date} |
      |_. Remaining Story Points <br> (includes all stories not <br> in a past iteration) | #{remaining_story_points} |_. #{empty_column_header}  | Worst velocity (#{worst_velocity}) | #{remaining_iters_for_worst} | #{worst_end_date} |
      |_. Iteration Length <br> (calculated based on <br> last iteration completed) | #{iter_length} days |_. #{empty_column_header} | #{empty_column} | #{empty_column} | #{empty_column} |

      <br>
        HTML

      end

    rescue Exception => e
      <<-ERROR
    h2. Release Metrics:

    "An Error occurred: #{e}"

      ERROR
    end
  end

  def card_link(card_identifier_name)
    return "#{card_name card_identifier_name} #{@project.identifier}/##{card_number card_identifier_name}" if @parameters['project']
    card_identifier_name
  end

  def remaining_iterations(velocity, remaining_story_points)
    return 'Unknown' if velocity <= 0
    (remaining_story_points/velocity).ceil
  end

  def expected_completion_date_for(last_end_date, iter_length, remaining_iterations)
    return 'Unknown' if remaining_iterations == 'Unknown'
    last_end_date + (iter_length * remaining_iterations)
  end

  def story_points_for(stories)
    stories.inject(0) do |total, story|
      story_points = story["#{story_points_parameter}"]
      story_points ? total + story_points.to_i : total
    end
  end

  def last_iteration_end_date(most_recent_iter)
    Date.parse(most_recent_iter[end_date_parameter])
  end

  def iteration_length_in_days(most_recent_iter)
    start_date = Date.parse(most_recent_iter[start_date_parameter])
    end_date = last_iteration_end_date(most_recent_iter)
    (end_date - start_date) + 1
  end

  def iteration_names(iterations)
    iterations.collect { |iter| "'#{iter['name']}'" }.join ","
  end

  def last_3_iterations(iterations)
    iterations.first(3)
  end

  def best_velocity_for(iterations)
    return 0 if iterations.length == 0
    iterations.inject(1) do |best, iter|
      velocity = iter[velocity_parameter]
      (velocity && velocity.to_i > best ? velocity.to_i : best).to_f
    end
  end

  def worst_velocity_for(iterations)
    return 0 if iterations.length == 0
    iterations.inject(best_velocity_for(iterations)) do |worst, iter|
      iter_velocity = iter[velocity_parameter].to_i
      iter_velocity && iter_velocity < worst && iter_velocity > 0 ? iter_velocity : worst
    end.to_f
  end

  def average_velocity(iterations)
    return 0 if iterations.length == 0
    total_velocity = iterations.inject(0) do |total, hash|
      velocity = hash[velocity_parameter]
      velocity ? total + velocity.to_i : total
    end
    total_velocity / (iterations.length * 1.0)
  end

  def release_end_date(release)
    release[end_date_parameter]
  end

  def current_release
    begin
      data_rows = @project.execute_mql("SELECT '#{end_date_field}' WHERE Number = #{card_number release_parameter}")
      raise "##{release_parameter} is not a valid release" if data_rows.empty?
      data_rows[0]
    rescue Exception => e
      raise "[error retrieving release for #{release_parameter}: #{e}]"
    end
  end

  def completed_iterations
    begin
      @project.execute_mql(
          "SELECT name, '#{start_date_field}', '#{end_date_field}', #{velocity_field} " +
              "WHERE Type = #{time_box_type} AND '#{end_date_field}' < today AND release = '#{card_name release_parameter}' " +
              "ORDER BY '#{end_date_field}' desc")
    rescue Exception => e
      raise "[error retrieving completed iterations for #{release_parameter}: #{e}]"
    end
  end

  def stories(completed_iterations, remaining_stories = true)
    return [] if completed_iterations.length == 0 && !remaining_stories
    iter_names = iteration_names completed_iterations
    if completed_iterations.length > 0
      mql = "SELECT '#{story_points_field}' WHERE Type = story AND release = '#{card_name release_parameter}' AND " +
          "#{remaining_stories ? 'NOT ' : ''}#{time_box_type} in (#{iter_names})"
    else
      mql = "SELECT '#{story_points_field}' WHERE Type = story AND release = '#{card_name release_parameter}'"
    end
    begin
      @project.execute_mql(mql)
    rescue Exception => e
      raise "[error retrieving stories for release '#{release_parameter}': #{e}]"
    end
  end

  def card_name(card_identifier_name)
    find_first_match(card_identifier_name, /#\d+ (.*)/)
  end

  def card_number(card_identifier_name)
    find_first_match(card_identifier_name, /#(\d+).*/).to_i
  end

  def find_first_match(data, regex)
    match_data = regex.match(data)
    if  match_data
      match_data[1]
    else
      'Unknown'
    end
  end

  def parameter_to_field(param)
    param.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
  end

  def can_be_cached?
    false # if appropriate, switch to true once you move your macro to production
  end

  #noinspection RubyUnusedLocalVariable
  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^(.*)_field$/
      parameter_to_field(send "#{$1}_parameter".to_s)
    elsif  method_sym.to_s =~ /^(.*)_(parameter|type)$/
      param = @parameters[$1] || @parameter_defaults[$1]
      if param.respond_to? :call
        param.call
      else
        param
      end
    else
      super
    end
  end

  def respond_to?(method_sym, include_private = false)
    puts 'in respond to'
    if method_sym.to_s =~ /^(.*)_[field|parameter|type]$/
      true
    else
      super
    end
  end

end

