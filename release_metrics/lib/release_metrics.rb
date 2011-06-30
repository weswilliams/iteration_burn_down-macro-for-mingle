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
  end

  def execute
    begin
      iterations = completed_iterations

      average_velocity = average_velocity last_3_iterations(iterations)
      best_velocity = best_velocity_for iterations
      worst_velocity = worst_velocity_for iterations

      remaining_stories = incomplete_stories iterations
      remaining_story_points = story_points_for remaining_stories
      last_end_date = last_iteration_end_date iterations[0]
      iter_length = iteration_length_in_days iterations[0]

      remaining_iters_for_avg = remaining_iterations(average_velocity, remaining_story_points)
      remaining_iters_for_best = remaining_iterations(best_velocity, remaining_story_points)
      remaining_iters_for_worst = remaining_iterations(worst_velocity, remaining_story_points)

      avg_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iters_for_avg
      best_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iters_for_best
      worst_end_date = expected_completion_date_for last_end_date, iter_length, remaining_iters_for_worst


      <<-HTML
    h2. Metrics for #{release}

    |_. Current Iteration | #{iteration} |_. - |_. Estimated Completion <br> for #{release} <br> Based on ... |_. Required <br> Iterations |_. Calculated End Date <br> Based on #{iter_length} Day Iterations |
    |_. Average Velocity <br> (last 3 iterations) | #{"%.2f" % average_velocity} |_. -  | Average velocity of <br> last 3 iterations (#{"%.2f" % average_velocity}) | #{remaining_iters_for_avg} | #{avg_end_date} |
    |_. Completed Iterations | #{iterations.length} |_. -  | Best velocity (#{best_velocity}) | #{remaining_iters_for_best} | #{best_end_date} |
    |_. Remaining Story Points <br> (includes all stories not <br> in a past iteration) | #{remaining_story_points} |_. -  | Worst velocity (#{worst_velocity}) | #{remaining_iters_for_worst} | #{worst_end_date} |
    |_. Iteration Length | #{iter_length} days |_. -  | - | - | - |

    <br>
      HTML
    rescue Exception => e
      <<-ERROR
    h2. Release Metrics:

    "An Error occurred: #{e}"

      ERROR
    end
  end

  def remaining_iterations(velocity, remaining_story_points)
    (remaining_story_points/velocity).ceil
  end

  def expected_completion_date_for(last_end_date, iter_length, remaining_iterations)
    last_end_date + (iter_length * remaining_iterations - 1)
  end

  def story_points_for(stories)
    stories.inject(0) {|total, story| story['story_points'] ? total + story['story_points'].to_i : total }
  end

  def incomplete_stories(iterations)
    iter_names = iteration_names iterations
    begin
      @project.execute_mql(
          "SELECT 'story points' WHERE Type = story AND release = '#{release_name}' AND NOT iteration in (#{iter_names})")
    rescue Exception => e
      raise "[error retrieving stories for release '#{release}': #{e}]"
    end
  end

  def last_iteration_end_date(most_recent_iter)
    Date.parse(most_recent_iter['end_date'])
  end

  def iteration_length_in_days(most_recent_iter)
    start_date = Date.parse(most_recent_iter['start_date'])
    end_date = last_iteration_end_date(most_recent_iter)
    (end_date - start_date) + 1
  end

  def iteration_names(iterations)
    iterations.collect {|iter| "'#{iter['name']}'" }.join ","
  end

  def last_3_iterations(iterations)
    iterations.first(3)
  end

  def best_velocity_for(iterations)
    iterations.inject(1) {|best, iter| iter['velocity'] && iter['velocity'].to_i > best ? iter['velocity'].to_i : best }.to_f
  end

  def worst_velocity_for(iterations)
    iterations.inject(best_velocity_for(iterations)) do |worst, iter|
      iter_velocity = iter['velocity'].to_i
      iter_velocity && iter_velocity < worst && iter_velocity > 0 ? iter_velocity : worst
    end.to_f
  end

  def average_velocity(iterations)
    total_velocity = iterations.inject(0) { |total, hash| hash['velocity'] ? total + hash['velocity'].to_i : total }
    total_velocity / (iterations.length * 1.0)
  end

  def completed_iterations
    begin
      data_rows = @project.execute_mql(
          "SELECT 'start date', 'end date', velocity WHERE Type = iteration AND 'End Date' < today AND release = '#{release_name}' ORDER BY 'end date' desc")
      raise "##{release} is not a valid release" if data_rows.empty?
      data_rows
    rescue Exception => e
      raise "[error retrieving completed iterations for #{release}: #{e}]"
    end
  end

  def release
    @parameters['release'] || @project.value_of_project_variable('Current Release')
  end

  def release_name
    match_data = /#\d+ (.*)/.match(release)
    if  match_data
      match_data[1]
    else
      'Unknown'
    end
  end

  def release_number
    match_data = /#(\d+).*/.match(release)
    if  match_data
      match_data[1].to_i
    else
      'Unknown'
    end
  end

  def iteration
    @parameters['iteration'] || @project.value_of_project_variable('Current Iteration')
  end

  def parameter_to_field(field)
    field.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
  end

  def today
    @parameters[:today] || Date.today
  end

  def can_be_cached?
    false # if appropriate, switch to true once you move your macro to production
  end

end

