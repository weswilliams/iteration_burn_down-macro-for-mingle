require "parameters"

module CustomMacro
  class FullTable
    include CustomMacro, CustomMacro::Parameters

    def initialize(project, release, what_if, parameters)
      @project = project
      @release = release
      @parameters = parameters
      @what_if = what_if
    end

    def render
      # make sure the #{full_table...} does not have spaces at the beginning of the line to avoid layout issues
      <<-HTML
      h2. Metrics for #{card_link release_parameter}

      * Scheduled End Date is #{@release.end_date}

#{full_table}

<span id='debug-info'></span>

#{ @what_if.javascript debug_parameter }
      HTML
    end

    def full_table
      WikiTableBuilder.
        table.
          row.
            col("Current Iteration").header.build.col(card_link iteration_parameter).build.col.header.build.
            col("Estimated Completion <br> of #{card_link release_parameter}").header.build.
            col("Required <br> Iterations").header.build.
            col("Calculated Development End Date <br> Based on #{@release.days_in_iteration} Day Iterations").header.build.
          build.
          row.
            col("Average Velocity <br> (last 3 iterations)").header.build.
            col("%.2f" % @release.last_3_average).build.col.header.build.
            col("Average velocity of <br> last 3 iterations (#{"%.2f" % @release.last_3_average})").build.
            col(@release.remaining_iters(:last_3_average)).build.col(@release.completion_date :last_3_average).build.
          build.
          row.
            col("Completed Iterations").header.build.col(@release.completed_iterations).build.col.header.build.
            col("Average velocity of <br> all iterations (#{"%.2f" % @release.average_velocity})").build.
            col(@release.remaining_iters(:average_velocity)).build.col(@release.completion_date :average_velocity).build.
          build.
          row.
            col("Completed Story Points").header.build.col(@release.completed_story_points).build.col.header.build.
            col("Best velocity (#{@release.best_velocity})").build.
            col(@release.remaining_iters(:best_velocity)).build.col(@release.completion_date :best_velocity).build.
          build.
          row.
            col("Remaining Story Points <br> (includes all stories not <br> in a past iteration)").header.build.
            col(@release.remaining_story_points).build.col.header.build.
            col("Worst velocity (#{@release.worst_velocity})").build.
            col(@release.remaining_iters(:worst_velocity)).build.col(@release.completion_date :worst_velocity).build.
          build.
          row.
            col("Iteration Length <br> (calculated based on <br> last iteration completed)").header.build.
            col("#{@release.days_in_iteration} days").build.col.header.build.
            col(@what_if.velocity_field).build.col(@what_if.iterations_field).build.col(@what_if.date_field).build.
          build.
        build
    end
    
  end
  
end
