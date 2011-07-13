require "date"
module CustomMacro

  def empty_column_header
    "%{color:#EEEEEE}-%"
  end

  def empty_column
      "%{color:white}-%"
  end

  class Release
    def initialize(data, end_data_parameter, iterations, remaining_stories)
      @data = data
      @end_data_parameter = end_data_parameter
      @iterations = iterations
      @remaining_stories = remaining_stories
    end

    def remaining_iters(velocity_method)
      velocity = @iterations.send velocity_method.to_s
      return 'Unknown' if velocity <= 0
      (@remaining_stories.story_points / velocity).ceil
    end

    def completion_date(velocity_method)
      remaining_iterations = remaining_iters velocity_method
      return 'Unknown' if remaining_iterations == 'Unknown'
      @iterations.last_end_date + (@iterations.days_in_iteration * remaining_iterations)
    end

    def end_date
      @data[@end_data_parameter]
    end
  end

  class Stories
    def initialize(data, story_points_parameter = 'story_points')
      @data = data
      @story_points_parameter = story_points_parameter
    end

    def story_points
      @data.inject(0) do |total, story|
        story_points = story["#{@story_points_parameter}"]
        story_points ? total + story_points.to_i : total
      end
    end

    def length
      @data.length
    end
  end

  class ReleaseMetrics
    include CustomMacro

    def initialize(parameters, project, current_user)
      @parameters = parameters
      @project = project
      @current_user = current_user
      @parameter_defaults = Hash.new { |h, k| h[k]=k }
      @parameter_defaults['iteration'] = lambda { @project.value_of_project_variable('Current Iteration') }
      @parameter_defaults['release'] = lambda { @project.value_of_project_variable('Current Release') }
      @parameter_defaults['time_box'] = 'iteration'
      @parameter_defaults['show_what_if'] = false
      @parameter_defaults['mini'] = false
    end

    def execute
      begin
        iterations = completed_iterations
        completed_stories = stories iterations, false
        remaining_stories = stories iterations
        release = current_release iterations, remaining_stories
        what_if = WhatIfScenario.new show_what_if_parameter, remaining_stories.story_points, iterations.last_end_date, iterations.days_in_iteration

        if mini_parameter

          <<-HTML
      |_. Scheduled End Date | #{release.end_date} |_. #{empty_column_header} |_. Estimated Completion <br> of #{card_link release_parameter} |_. Required <br> Iterations |_. Calculated Development End Date <br> Based on #{iterations.days_in_iteration} Day Iterations |
      |_. Completed Story Points | #{completed_stories.story_points} |_. #{empty_column_header}  | Average velocity of <br> last 3 iterations (#{"%.2f" % iterations.last_3_average}) | #{release.remaining_iters(:last_3_average)} | #{release.completion_date :last_3_average} |
      |_. Remaining Story Points | #{remaining_stories.story_points} |_. #{empty_column_header}  |Average velocity of <br> all iterations (#{"%.2f" % iterations.average_velocity}) | #{release.remaining_iters(:average_velocity)} | #{release.completion_date :average_velocity} |
          HTML

        else
          <<-HTML
      h2. Metrics for #{card_link release_parameter}

      * Scheduled End Date is #{release.end_date}

      |_. Current Iteration | #{card_link iteration_parameter} |_. #{empty_column_header} |_. Estimated Completion <br> of #{card_link release_parameter} <br> Based on ... |_. Required <br> Iterations |_. Calculated Development End Date <br> Based on #{iterations.days_in_iteration} Day Iterations |
      |_. Average Velocity <br> (last 3 iterations) | #{"%.2f" % iterations.last_3_average} |_. #{empty_column_header}  | Average velocity of <br> last 3 iterations (#{"%.2f" % iterations.last_3_average}) | #{release.remaining_iters(:last_3_average)} | #{release.completion_date :last_3_average} |
      |_. Completed Iterations | #{iterations.length} |_. #{empty_column_header}  |Average velocity of <br> all iterations (#{"%.2f" % iterations.average_velocity }) | #{release.remaining_iters(:average_velocity)} | #{release.completion_date :average_velocity} |
      |_. Completed Story Points | #{completed_stories.story_points} |_. #{empty_column_header}  | Best velocity (#{iterations.best_velocity}) | #{release.remaining_iters(:best_velocity)} | #{release.completion_date :best_velocity} |
      |_. Remaining Story Points <br> (includes all stories not <br> in a past iteration) | #{remaining_stories.story_points} |_. #{empty_column_header}  | Worst velocity (#{iterations.worst_velocity}) | #{release.remaining_iters(:worst_velocity)} | #{release.completion_date :worst_velocity} |
      |_. Iteration Length <br> (calculated based on <br> last iteration completed) | #{iterations.days_in_iteration} days |_. #{empty_column_header} | #{what_if.velocity_field} | #{ what_if.iterations_field } | #{ what_if.date_field } |

#{ what_if.javascript }
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

    def current_release(iterations, remaining_stories)
      begin
        release_where = "Number = #{card_number release_parameter}"
        release_where = "Number = #{release_parameter}.'Number'" if release_parameter == 'THIS CARD'
        data_rows = @project.execute_mql("SELECT '#{end_date_field}' WHERE #{release_where}")
        raise "##{release_parameter} is not a valid release" if data_rows.empty?
        Release.new data_rows[0], end_date_parameter, iterations, remaining_stories
      rescue Exception => e
        raise "[error retrieving release for #{release_parameter}: #{e}]"
      end
    end

    def completed_iterations
      begin
        completed_iterations = @project.execute_mql(
            "SELECT name, '#{start_date_field}', '#{end_date_field}', #{velocity_field} " +
                "WHERE Type = #{time_box_type} AND '#{end_date_field}' < today AND #{release_where} " +
                "ORDER BY '#{end_date_field}' desc")
        Iterations.new completed_iterations, velocity_parameter, end_date_parameter, start_date_parameter
      rescue Exception => e
        raise "[error retrieving completed iterations for #{release_parameter}: #{e}]"
      end
    end

    def release_where
      release_parameter == 'THIS CARD' ? "release = #{release_parameter}" : "release = '#{card_name release_parameter}'"
    end

    def stories(completed_iterations, remaining_stories = true)
      return [] if completed_iterations.length == 0 && !remaining_stories
      iter_names = completed_iterations.names
      if completed_iterations.length > 0
        mql = "SELECT '#{story_points_field}' WHERE Type = story AND #{release_where} AND " +
            "#{remaining_stories ? 'NOT ' : ''}#{time_box_type} in (#{iter_names})"
      else
        mql = "SELECT '#{story_points_field}' WHERE Type = story AND #{release_where}"
      end
      begin
        Stories.new @project.execute_mql(mql), story_points_parameter
      rescue Exception => e
        raise "[error retrieving stories for release '#{release_parameter}': #{e}]"
      end
    end

    def card_link(card_identifier_name)
      return "#{card_name card_identifier_name} #{@project.identifier}/##{card_number card_identifier_name}" if @parameters['project']
      card_identifier_name
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

end

