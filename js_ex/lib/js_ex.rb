require "date"

module CustomMacro

  class JsEx

    def initialize(parameters, project, current_user)
      @parameters = parameters
      @project = project
      @current_user = current_user
      @parameter_defaults = {}

   end

    def execute
      begin
        from_date = Date.parse('2011-07-04')
        days = 7

        <<-HTML
    h2. JavaScript Example

    <div id="js-output" style="width: 200px; height: 100px">loading...</div>
    <input type='text' id='text-for-js'></input>
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
    <script type="text/javascript">
      jQuery.noConflict();
      // register the initialize function for executing after page loaded.
      MingleJavascript.register(function initialize() {

        var fromDate = new Date('#{from_date.to_s}');
        var daysInIter = #{days};

        var out = jQuery("#js-output");
        out.html('<span>updated with jQuery</span>');

        jQuery("#text-for-js").blur(function() {
          var iterations = parseInt(jQuery("#text-for-js").val());
          var expectedDate = new Date(fromDate.getTime() + 1000 * 60 * 60 * 24 * (daysInIter * iterations));
          out.html("<span>you entered " + iterations + ", " + daysInIter + ", " + expectedDate + "</span>");
        });
      });
    </script>

        HTML
      rescue Exception => e
        <<-ERROR
    h2. JavaScript Example

    "An Error occurred: #{e}"
        ERROR
      end
    end

    def parameter_to_field(field)
      field.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
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
