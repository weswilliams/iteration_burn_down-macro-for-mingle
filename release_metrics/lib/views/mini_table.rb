require "parameters"

module CustomMacro
  class MiniTable
    include CustomMacro, CustomMacro::Parameters

    def initialize(project, release, parameters)
      @project = project
      @release = release
      @parameters = parameters
    end

    def render
      WikiTableBuilder.
        table.
          row.
            col("Scheduled End Date").header.build.col(@release.end_date).build.col.header.build.
            col("Estimated Completion <br> of #{card_link release_parameter}").header.build.
            col("Required <br> Iterations").header.build.
            col("Calculated Development End Date <br> Based on #{@release.days_in_iteration} Day Iterations").header.build.
          build.
          row.
            col("Completed Story Points").header.build.col(@release.completed_story_points).build.col.header.build.
            col("Average velocity of <br> last 3 iterations (#{"%.2f" % @release.last_3_average})").build.
            col(@release.remaining_iters(:last_3_average)).build.col(@release.completion_date :last_3_average).build.
          build.
          row.
            col("Remaining Story Points").header.build.col(@release.remaining_story_points).build.col.header.build.
            col("Average velocity of <br> all iterations (#{"%.2f" % @release.average_velocity})").build.
            col(@release.remaining_iters(:average_velocity)).build.col(@release.completion_date :average_velocity).build.
          build.
        build
    end
  end
end
