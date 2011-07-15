require "date"
module CustomMacro

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
      @parameter_defaults['debug'] = false
    end

    def execute
      begin
        iterations = completed_iterations
        release_data = {
          :iterations => iterations,
          :remaining_stories => stories(iterations),
          :completed_stories => stories(iterations, false)
        }
        release = current_release release_data
        what_if = WhatIfScenario.new show_what_if_parameter, release
        if mini_parameter
          mini_table release
        else
          full_metrics(release, what_if)
        end
      rescue Exception => e
        error_view(e)
      end
    end

    def full_metrics(release, what_if)
      # make sure the #{full_table...} does not have spaces at the beginning of the line to avoid layout issues
      <<-HTML
      h2. Metrics for #{card_link release_parameter}

      * Scheduled End Date is #{release.end_date}

#{full_table release, what_if}

<span id='debug-info'></span>

#{ what_if.javascript debug_parameter }
      HTML
    end

    def full_table(release, what_if)
      WikiTableBuilder.
          table.
            row.
              col("Current Iteration").header.build.col(card_link iteration_parameter).build.col.header.build.
              col("Estimated Completion <br> of #{card_link release_parameter}").header.build.
              col("Required <br> Iterations").header.build.
              col("Calculated Development End Date <br> Based on #{release.days_in_iteration} Day Iterations").header.build.
            build.
            row.
              col("Average Velocity <br> (last 3 iterations)").header.build.
              col("%.2f" % release.last_3_average).build.col.header.build.
              col("Average velocity of <br> last 3 iterations (#{"%.2f" % release.last_3_average})").build.
              col(release.remaining_iters(:last_3_average)).build.col(release.completion_date :last_3_average).build.
            build.
            row.
              col("Completed Iterations").header.build.col(release.completed_iterations).build.col.header.build.
              col("Average velocity of <br> all iterations (#{"%.2f" % release.average_velocity})").build.
              col(release.remaining_iters(:average_velocity)).build.col(release.completion_date :average_velocity).build.
            build.
            row.
              col("Completed Story Points").header.build.col(release.completed_story_points).build.col.header.build.
              col("Best velocity (#{release.best_velocity})").build.
              col(release.remaining_iters(:best_velocity)).build.col(release.completion_date :best_velocity).build.
            build.
            row.
              col("Remaining Story Points <br> (includes all stories not <br> in a past iteration)").header.build.
              col(release.remaining_story_points).build.col.header.build.
              col("Worst velocity (#{release.worst_velocity})").build.
              col(release.remaining_iters(:worst_velocity)).build.col(release.completion_date :worst_velocity).build.
            build.
            row.
              col("Iteration Length <br> (calculated based on <br> last iteration completed)").header.build.
              col("#{release.days_in_iteration} days").build.col.header.build.
              col(what_if.velocity_field).build.col(what_if.iterations_field).build.col(what_if.date_field).build.
            build.
          build
    end

    def mini_table(release)
      WikiTableBuilder.
          table.
            row.
              col("Scheduled End Date").header.build.col(release.end_date).build.col.header.build.
              col("Estimated Completion <br> of #{card_link release_parameter}").header.build.
              col("Required <br> Iterations").header.build.
              col("Calculated Development End Date <br> Based on #{release.days_in_iteration} Day Iterations").header.build.
            build.
            row.
              col("Completed Story Points").header.build.col(release.completed_story_points).build.col.header.build.
              col("Average velocity of <br> last 3 iterations (#{"%.2f" % release.last_3_average})").build.
              col(release.remaining_iters(:last_3_average)).build.col(release.completion_date :last_3_average).build.
            build.
            row.
              col("Remaining Story Points").header.build.col(release.remaining_story_points).build.col.header.build.
              col("Average velocity of <br> all iterations (#{"%.2f" % release.average_velocity})").build.
              col(release.remaining_iters(:average_velocity)).build.col(release.completion_date :average_velocity).build.
            build.
          build
    end

    def error_view(e)
      <<-ERROR
    h2. Release Metrics:

    "An Error occurred: #{e}"

      ERROR
    end

    def current_release(release_data)
      begin
        release_where = "Number = #{card_number release_parameter}"
        release_where = "Number = #{release_parameter}.'Number'" if release_parameter == 'THIS CARD'
        data_rows = @project.execute_mql("SELECT '#{end_date_field}' WHERE #{release_where}")
        raise "##{release_parameter} is not a valid release" if data_rows.empty?
        Release.new data_rows[0], end_date_parameter, release_data
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
      if method_sym.to_s =~ /^(.*)_[field|parameter|type]$/
        true
      else
        super
      end
    end

  end

end

