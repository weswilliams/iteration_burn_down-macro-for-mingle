#Copyright 2010 ThoughtWorks, Inc.  All rights reserved.

module FixtureLoaders
  class Base
    
    def initialize(attributes)
      @attributes = attributes
    end
    
    def load_fixtures_for(name)
      path = File.join(File.dirname(__FILE__), '..', 'fixtures', "sample", "#{name}.yml")
      YAML::load(File.read(path))
    end
    
    def match?(record)
      @attributes.all? { |key, value| value == record[key] }
    end
  end

  class ProjectLoader < Base
    attr_reader :project

    def initialize(identifier)
      project_attributes = load_fixtures_for('projects').detect {|project| project['identifier'] == identifier }
      @project = Mingle::Project.new(OpenStruct.new(project_attributes), nil)
      project.card_types_loader = CardTypesLoader.new('project_id' => project_attributes['id'])
      project.property_definitions_loader = PropertyDefinitionsLoader.new('project_id' => project_attributes['id'])
      project.team_loader = TeamLoader.new('project_id' => project_attributes['id'])
      project.project_variables_loader = ProjectVariablesLoader.new('project_id' => project_attributes['id'])
    end
  end
  
  class CardTypesLoader < Base
    def load
      load_fixtures_for('card_types').collect do |ct|
        CardTypeLoader.new('id' => ct['id']) if match?(ct)
      end.compact.sort_by { |loader| loader.card_type.position }
    end
  end
  
  class CardTypeLoader < Base
    def card_type
      @card_type ||= load
    end
    
    def load
      record = load_fixtures_for('card_types').find {|ct| match?(ct)}
      card_type = Mingle::CardType.new(OpenStruct.new(record))
      card_type.card_types_property_definitions_loader = CardTypesPropertyDefinitionsLoader.new('card_type_id' => record['id'])
      card_type
    end
  end
  
  class PropertyDefinitionsLoader < Base
    def load
      load_fixtures_for('property_definitions').collect do |pd|
        PropertyDefinitionLoader.new('id' => pd['id']) if match?(pd)
      end.compact
    end
  end
  
  class PropertyDefinitionLoader < Base
    def property_definition
      @property_definition ||= load
    end
    
    def load
      record = load_fixtures_for('property_definitions').find { |pd| match?(pd)}
      property_definition = Mingle::PropertyDefinition.new(OpenStruct.new(record))
      property_definition.card_types_property_definitions_loader = CardTypesPropertyDefinitionsLoader.new('property_definition_id' => record['id'])
      property_definition.values_loader = PropertyValuesLoader.new('property_definition_id' => record['id'])
      property_definition
    end
  end
  
  class PropertyValuesLoader < Base
    def load
      load_fixtures_for('property_values').collect do |pv|
        Mingle::PropertyValue.new(OpenStruct.new(pv)) if match?(pv)
      end.compact
    end
  end

  class CardTypesPropertyDefinitionsLoader < Base
    def load
      load_fixtures_for('property_type_mappings').collect do |mapping|
        pd = PropertyDefinitionLoader.new('id' => mapping['property_definition_id']) if match?(mapping)
        ct = CardTypeLoader.new('id' => mapping['card_type_id']) if match?(mapping)
        OpenStruct.new(:card_type => ct.load, :property_definition => pd.load) if ct && pd
      end.compact
    end
  end
  
  class TeamLoader < Base
    def load
      load_fixtures_for('users').collect do |user|
        Mingle::User.new(OpenStruct.new(user)) if match?(user)
      end.compact
    end
  end
  
  class ProjectVariablesLoader < Base
    def load
      load_fixtures_for('project_variables').collect do |pv|
        Mingle::ProjectVariable.new(OpenStruct.new(pv)) if match?(pv)
      end.compact
    end
  end
end
