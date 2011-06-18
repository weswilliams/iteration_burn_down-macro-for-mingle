#Copyright 2010 ThoughtWorks, Inc.  All rights reserved.

module RESTfulLoaders

  class RemoteError < StandardError
    def self.parse(response_body)
      Hash.from_xml(response_body)['errors'].delete("error")
    end
  end

  module LoaderHelper
    
    def extract(key, container)
      container[key] ? container[key][key.singularize] : []
    end
    
    def get(resource)
      url = URI.parse(resource)
      get_request = Net::HTTP::Get.new(url.request_uri)
      get_request.basic_auth(url.user, url.password)
      response = Net::HTTP.start(url.host, url.port) { |http| http.request(get_request) }
      if response.code.to_s != "200"
        raise RemoteError, RemoteError.parse(response.body)
      end  
      Hash.from_xml(response.body)
    end
  end
  
  class MqlExecutor < SimpleDelegator
    include LoaderHelper

    def initialize(resource, error_handler, delegator)
      super(delegator)
      @uri = URI.parse(resource)
      @error_handler = error_handler
      @version = /(\/api\/([^\/]*))\//.match(@uri.request_uri)[2]
    end

    def execute_mql(mql)
      from_xml_data(get(url_for(:action => "execute_mql", :query => "mql=#{mql}")))
    rescue => e
      @error_handler.alert(e.message)
      []
    end
    
    def can_be_cached?(mql)
      from_xml_data(get(url_for(:action => "can_be_cached", :query => "mql=#{mql}")))
    rescue => e
      @error_handler.alert(e.message)
      []
    end
    
    def format_number_with_project_precision(number)
      from_xml_data(get(url_for(:action => "format_number_to_project_precision", :query => "number=#{number}")))
    rescue => e
      @error_handler.alert(e.message)
      []
    end
    
    def format_date_with_project_date_format(date)
      from_xml_data(get(url_for(:action => "format_string_to_date_format", :query => "date=#{date}")))
    rescue => e
      @error_handler.alert(e.message)
      []
    end

    def url_for(params)
      relative_path = URI.escape("/api/#{@version}/projects/#{identifier}/cards/#{params[:action]}.xml?#{params[:query]}")
      @uri.merge(relative_path).to_s
    end

    def from_xml_data(data)
      if data.is_a?(Hash) && data.keys.size == 1
        from_xml_data(data.values.first)
      else
        data
      end
    end
  end

  class ProjectLoader
    include LoaderHelper
    
    def initialize(resource, error_handler)
      @resource = resource
      @error_handler = error_handler
    end
    
    def project
      @project ||= load
    end
    
    private

    def load
      proj = OpenStruct.new(get(@resource)).project
      project = MqlExecutor.new(@resource, @error_handler, Mingle::Project.new(OpenStruct.new(proj), nil))
      project.card_types_loader = CardTypesLoader.new(proj)
      project.property_definitions_loader = PropertyDefinitionsLoader.new(proj)
      project.team_loader = TeamLoader.new(proj)
      project.project_variables_loader = ProjectVariablesLoader.new(proj)
      project
    end

  end
  
  class CardTypesLoader
    include LoaderHelper
    
    def initialize(project)
      @project = project
    end
    
    def load
      extract('card_types', @project).collect { |ct| CardTypeLoader.new(@project, ct) }.sort_by { |loader| loader.card_type.position }
    end
  end
  
  class CardTypeLoader
    
    def initialize(project, ct)
      @project = project
      @ct = ct
    end
    
    def card_type
      @card_type ||= load
    end
    
    def load
      card_type = Mingle::CardType.new(OpenStruct.new(@ct))
      card_type.card_types_property_definitions_loader = CardTypesPropertyDefinitionsLoader.new(@project, 'card_type_id' => @ct['id'])
      card_type
    end
  end

  class PropertyDefinitionsLoader
    include LoaderHelper
    
    def initialize(project)
      @project = project
    end
    
    def load
      extract('property_definitions', @project).collect { |pd| PropertyDefinitionLoader.new(@project, pd) }
    end
  end
  
  class PropertyDefinitionLoader
    def initialize(project, pd)
      @project = project
      @pd = pd
    end
    
    def property_definition
      @property_definition ||= load
    end
    
    def load
      @property_definition = Mingle::PropertyDefinition.new(OpenStruct.new(@pd))
      @property_definition.card_types_property_definitions_loader = CardTypesPropertyDefinitionsLoader.new(@project, 'property_definition_id' => @pd['id'])
      @property_definition.values_loader = PropertyValuesLoader.new(@pd)
      @property_definition
    end
  end
  
  class PropertyValuesLoader
    include LoaderHelper
    
    def initialize(property_definition)
      @property_definition = property_definition
    end
    
    def load
      extract('values', @property_definition).collect {|value| Mingle::PropertyValue.new(OpenStruct.new(value))}
    end
    
  end
  
  class CardTypesPropertyDefinitionsLoader
    include LoaderHelper
    
    def initialize(project, params)
      @project = project
      @params = params
    end
    
    def load
      mappings = extract('card_types', @project).collect do |card_type|
        mapping = card_type['card_types_property_definitions'].values
      end.flatten
      
      pds = extract('property_definitions', @project)
      cts = extract('card_types', @project)
      mappings.collect do |mapping|
        if (match?(mapping))
          pd = pds.find { |pd| pd['id'] && pd['id'] == mapping['property_definition_id'] }
          ct = cts.find { |ct| ct['id'] == mapping['card_type_id'] }
          OpenStruct.new(:card_type => CardTypeLoader.new(@project, ct).load, :property_definition => PropertyDefinitionLoader.new(@project, pd).load)
        end
      end.compact
    end
    
    private
    def match?(mapping)
      @params.all? { |key, value| value == mapping[key] }
    end
  end
  
  class TeamLoader
    include LoaderHelper
    
    def initialize(project)
      @project = project
    end
    
    def load
      (extract('users', @project) || []).collect{ |user| Mingle::User(OpenStruct.new(user))}
    end
  end
  
  class ProjectVariablesLoader
    include LoaderHelper
    
    def initialize(project)
      @project = project
    end
    
    def load
      extract('project_variables', @project).collect {|pv| Mingle::ProjectVariable.new(OpenStruct.new(pv))}
    end
  end
end
