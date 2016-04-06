require 'google/apis/androidpublisher_v2'
require 'multi_json'

module CandyCheck
  module PlayStore
    # A client which uses the official Google API SDK to authenticate
    # and request product information from Google's API.
    #
    # @example Usage
    #   config = ClientConfig.new({...})
    #   client = Client.new(config)
    #   client.boot! # a single time
    #   client.verify('my.bundle', 'product_1', 'a-very-long-secure-token')
    #   # ... multiple calls from now on
    #   client.verify('my.bundle', 'product_1', 'another-long-token')
    class Client
      # API endpoint
      API_URL      = 'https://accounts.google.com/o/oauth2/token'.freeze
      # API scope for Android services
      API_SCOPE    = 'https://www.googleapis.com/auth/androidpublisher'.freeze
      # Alias from Google
      GoogleApi = Google::Apis::AndroidpublisherV2

      # Initializes a client using a configuration.
      # @param config [ClientConfig]
      def initialize(config)
        self.config = config
      end

      # Boots a client by discovering the API's services and then authorizes
      # by fetching an access token.
      # If the config has a cache_file the client tries to load discovery
      def boot!
        self.api_client = GoogleApi::AndroidPublisherService.new.tap do |client|
          client.client_options.application_name = config.application_name
          client.client_options.application_version = config.application_version
        end
        authorize!
      end

      # Calls the remote API to load the product information for a specific
      # combination of parameter which should be loaded from the client.
      # @param package [String] the app's package name
      # @param product_id [String] the app's item id
      # @param token [String] the purchase token
      # @return [Hash] result of the API call
      def verify(package, product_id, token)
        response = api_client.get_purchase_product(package, product_id, token)
        MultiJson.load(response.to_json)
      rescue Google::Apis::Error => error
        return {} unless error.body
        MultiJson.load(error.body)
      end

      private

      attr_accessor :config, :api_client

      def authorize!
        api_client.authorization = Signet::OAuth2::Client.new(
          token_credential_uri: API_URL,
          audience:             API_URL,
          scope:                API_SCOPE,
          issuer:               config.issuer,
          signing_key:          config.api_key
        )
        api_client.authorization.fetch_access_token!
      end
    end
  end
end
