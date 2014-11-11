# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

module NewRelic
  module Agent
    module GrapeInstrumentation
      API_ENDPOINT = 'api.endpoint'.freeze
      ROUTE_INFO   = 'route_info'.freeze
      FORMAT       = '(.:format)'.freeze
      EMPTY_STRING = ''.freeze
    end
  end
end

DependencyDetection.defer do
  named :grape

  depends_on do
    defined?(::Grape) && defined?(::Grape::API)
  end

  executes do
    NewRelic::Agent.logger.info 'Installing Grape instrumentation'
    install_grape_instrumentation
  end

  def install_grape_instrumentation
    instrument_call
  end

  def instrument_call
    ::Grape::API.class_eval do
      def call_with_new_relic(env)
        begin
          response = call_without_new_relic(env)
        ensure
          endpoint = env[::NewRelic::Agent::GrapeInstrumentation::API_ENDPOINT]

          if endpoint
            route_obj   = endpoint.params[::NewRelic::Agent::GrapeInstrumentation::ROUTE_INFO]
            action_name = route_obj.route_path.gsub(::NewRelic::Agent::GrapeInstrumentation::FORMAT,
                                                    ::NewRelic::Agent::GrapeInstrumentation::EMPTY_STRING)
            method_name = route_obj.route_method

            txn_name = "#{self.class.name}#{action_name} (#{method_name})"
            ::NewRelic::Agent.set_transaction_name(txn_name)
          end
        end

        response
      end

      alias_method :call_without_new_relic, :call
      alias_method :call, :call_with_new_relic
    end
  end

end
