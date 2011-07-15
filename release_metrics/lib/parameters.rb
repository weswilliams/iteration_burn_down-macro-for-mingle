module CustomMacro

  module Parameters

    def parameters
      @parameters || {}
    end

    def parameter_defaults
      @parameter_defaults || Hash.new { |h, k| h[k]=k }
    end

    def parameter_to_field(param)
      param.gsub('_', ' ').scan(/\w+/).collect { |word| word.capitalize }.join(' ')
    end

    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^(.*)_field$/
        parameter_to_field(send "#{$1}_parameter".to_s)
      elsif  method_sym.to_s =~ /^(.*)_(parameter|type)$/
        puts "missing: #{parameters.object_id} - #{parameter_defaults.object_id}"
        param = parameters[$1] || parameter_defaults[$1]
        if param.respond_to? :call
          param.call
        else
          param
        end
      else
        super method_sym, *arguments, &block
      end
    end

    def respond_to?(method_sym, include_private = false)
      if method_sym.to_s =~ /^(.*)_[field|parameter|type]$/
        true
      else
        super method_sym, include_private
      end
    end

  end

end