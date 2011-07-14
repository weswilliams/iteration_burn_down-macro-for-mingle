module CustomMacro

  class WhatIfScenario
    include CustomMacro

    def initialize(is_enabled, remaining_story_points, last_iter_end_date, days_in_iter)
      @is_enabled = is_enabled
      @remaining_story_points = remaining_story_points
      @last_iter_end_date = last_iter_end_date
      @days_in_iter = days_in_iter
    end

    def javascript
      return '' if !@is_enabled
      <<-JAVASCRIPT
<span id='debug-info'></span>

<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
<script language="javascript" type="text/javascript" src="../../../../plugin_assets/release_metrics/javascripts/what.if.js"></script>
<script type="text/javascript">
  jQuery.noConflict();
  // register the initialize function for executing after page loaded.
  MingleJavascript.register(function initialize() {
    try {
      whatIf.init(#{@days_in_iter}, #{@remaining_story_points}, new Date('#{@last_iter_end_date.to_s}'));
    } catch(err) {
      alert(err);
    }
  });
</script>

      JAVASCRIPT
    end

    def velocity_field(disabled_value = $empty_column)
      @is_enabled ? "What if velocity: <input type='text' id='what-if-velocity'></input>" : disabled_value
    end

    def iterations_field(disabled_value = $empty_column)
      @is_enabled ? "<span id='what-if-iterations'></span>" : disabled_value
    end

    def date_field(disabled_value = $empty_column)
      @is_enabled ? "What if date: <input type='text' id='what-if-date'></input>" : disabled_value
    end

  end

end