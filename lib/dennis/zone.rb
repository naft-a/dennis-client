# frozen_string_literal: true

require 'dennis/validation_error'
require 'dennis/group_not_found_error'

module Dennis
  class Zone

    class << self

      def all(client)
        groups = client.api.perform(:get, 'zones')
        groups.hash['zones'].map { |hash| new(client, hash) }
      end

      def find_by(client, field, value)
        request = client.api.create_request(:get, 'zones/:zone')
        request.arguments[:zone] = { field => value }
        new(client, request.perform.hash['zone'])
      rescue RapidAPI::RequestError => e
        e.code == 'zone_not_found' ? nil : raise
      end

      def create(client, group:, name:, external_reference: nil)
        request = client.api.create_request(:post, 'zones')
        request.arguments[:group] = group
        request.arguments[:properties] = { name: name, external_reference: external_reference }
        new(client, request.perform.hash['zone'])
      rescue RapidAPI::RequestError => e
        raise GroupNotFoundError if e.code == 'group_not_found'
        raise ValidationError, e.detail['errors'] if e.code == 'validation_error'

        raise
      end

    end

    def initialize(client, hash)
      @client = client
      @hash = hash
    end

    def id
      @hash['id']
    end

    def name
      @hash['name']
    end

    def external_reference
      @hash['external_reference']
    end

    def update(properties)
      req = @client.api.create_request(:patch, 'zones/:zone')
      req.arguments['zone'] = { id: id }
      req.arguments['properties'] = properties
      @hash = req.perform.hash['zone']
      true
    rescue RapidAPI::RequestError => e
      raise ValidationError, e.detail['errors'] if e.code == 'validation_error'

      raise
    end

    def delete
      req = @client.api.create_request(:delete, 'zones/:zone')
      req.arguments['zone'] = { id: id }
      req.perform
      true
    end

  end
end