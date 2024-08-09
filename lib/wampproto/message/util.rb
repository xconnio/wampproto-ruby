# frozen_string_literal: true

module Wampproto
  # message module
  module Message
    # fields
    class Fields
      attr_accessor :request_id, :uri, :args, :kwargs, :session_id, :realm, :authid,
                    :authrole, :authmethod, :authmethods, :authextra, :roles,
                    :message_type, :signature, :reason, :topic, :extra,
                    :options, :details, :subscription_id, :publication_id,
                    :registration_id
    end

    # util module
    module Util # rubocop:disable Metrics/ModuleLength
      MIN_ID = 1
      MAX_ID = 1 << 53
      DEFAULT_ROLES = { caller: {}, publisher: {}, subscriber: {}, callee: {} }.freeze

      module_function

      def validate_int(value, index, message)
        return nil if value.is_a?(Integer)

        format(
          Exceptions::INVALID_DATA_TYPE_ERROR,
          message:,
          index:,
          expected_type: "int",
          actual_type: value.class
        )
      end

      def validate_string(value, index, message)
        return nil if value.is_a?(String)

        format(
          Exceptions::INVALID_DATA_TYPE_ERROR,
          message:,
          index:,
          expected_type: "string",
          actual_type: value.class
        )
      end

      def validate_list(value, index, message)
        return nil if value.is_a?(Array)

        format(
          Exceptions::INVALID_DATA_TYPE_ERROR,
          message:,
          index:,
          expected_type: "list",
          actual_type: value.class
        )
      end

      def validate_hash(value, index, message)
        return nil if value.is_a?(Hash)

        format(
          Exceptions::INVALID_DATA_TYPE_ERROR,
          message:,
          index:,
          expected_type: "hash",
          actual_type: value.class
        )
      end

      def validate_id(value, index, message) # rubocop: disable Metrics/MethodLength
        error = validate_int(value, index, message)
        return error if error

        if (value < MIN_ID) || (value > MAX_ID)
          return format(
            Exceptions::INVALID_RANGE_ERROR,
            message:,
            index:,
            start: MIN_ID,
            end: MAX_ID,
            actual: value
          )
        end

        nil
      end

      def validate_request_id(wamp_msg, index, fields, message)
        error = validate_id(wamp_msg[index], index, message)

        return error if error

        fields.request_id = wamp_msg[index]
        nil
      end

      def validate_uri(wamp_msg, index, fields, message)
        error = validate_string(wamp_msg[index], index, message)

        return error if error

        fields.uri = wamp_msg[index]
        nil
      end

      def validate_args(wamp_msg, index, fields, message)
        if wamp_msg.length > index
          error = validate_list(wamp_msg[index], index, message)

          return error if error

          fields.args = wamp_msg[index]
        end
        nil
      end

      def validate_kwargs(wamp_msg, index, fields, message)
        if wamp_msg.length > index
          error = validate_hash(wamp_msg[index], index, message)

          return error if error

          fields.kwargs = wamp_msg[index]
        end
        nil
      end

      def validate_session_id(wamp_msg, index, fields, message)
        error = validate_id(wamp_msg[index], index, message)

        return error if error

        fields.session_id = wamp_msg[index]
        nil
      end

      def validate_realm(wamp_msg, index, fields, message)
        error = validate_string(wamp_msg[index], index, message)

        return error if error

        fields.realm = wamp_msg[index]
        nil
      end

      def validate_authid(details, index, fields, message) # rubocop: disable Metrics/MethodLength
        if details.key?("authid")
          authid = details["authid"]
          error = validate_string(authid, index, message)
          new_error = format(
            Exceptions::INVALID_DETAIL_ERROR,
            message:,
            index:,
            key: "authid",
            expected_type: "string",
            actual_type: authid.class
          )

          return new_error if error

          fields.authid = authid
        end

        nil
      end

      def validate_authrole(details, index, fields, message) # rubocop:disable Metrics/MethodLength
        if details.key?("authrole")
          authrole = details["authrole"]
          error = validate_string(authrole, index, message)
          new_error = format(
            Exceptions::INVALID_DETAIL_ERROR,
            message:,
            index:,
            key: "authrole",
            expected_type: "string",
            actual_type: authrole.class
          )

          return new_error if error

          fields.authrole = authrole
        end

        nil
      end

      def validate_authmethod(wamp_msg, index, fields, message)
        error = validate_string(wamp_msg[index], index, message)

        return error if error

        fields.authmethod = wamp_msg[index]
        nil
      end

      def validate_authmethods(details, index, fields, message) # rubocop:disable Metrics/MethodLength
        if details.key?("authmethods")
          authmethods = details["authmethods"]
          error = validate_list(authmethods, index, message)
          new_error = format(
            Exceptions::INVALID_DETAIL_ERROR,
            message:,
            index:,
            key: "authmethods",
            expected_type: "list",
            actual_type: authmethods.class
          )

          return new_error if error

          fields.authmethods = authmethods
        end

        nil
      end

      def validate_welcome_authmethod(details, index, fields, message) # rubocop:disable Metrics/MethodLength
        if details.key?("authmethod")
          authmethod = details["authmethod"]
          error = validate_string(authmethod, index, message)
          new_error = format(
            Exceptions::INVALID_DETAIL_ERROR,
            message:,
            index:,
            key: "authmethod",
            expected_type: "string",
            actual_type: authmethod.class
          )

          return new_error if error

          fields.authmethod = authmethod
        end

        nil
      end

      def validate_authextra(details, index, fields, message) # rubocop:disable Metrics/MethodLength
        if details.key?("authextra")
          authextra = details["authextra"]
          error = validate_hash(authextra, index, message)
          new_error = format(
            Exceptions::INVALID_DETAIL_ERROR,
            message:,
            index:,
            key: "authextra",
            expected_type: "hash",
            actual_type: authextra.class
          )

          return new_error if error

          fields.authextra = authextra
        end

        nil
      end

      def validate_roles(details, index, fields, message) # rubocop:disable Metrics/MethodLength
        if details.key?("roles")
          roles = details["roles"]
          error = validate_hash(roles, index, message)
          new_error = format(
            Exceptions::INVALID_DETAIL_ERROR,
            message:,
            index:,
            key: "roles",
            expected_type: "hash",
            actual_type: roles.class
          )

          return new_error if error

          valid_keys = DEFAULT_ROLES.keys
          invalid_keys = roles.keys - valid_keys

          if invalid_keys.any?
            return "#{message}: value at index #{index} for roles key must be in #{valid_keys} but was #{invalid_keys}"
          end

          fields.roles = roles
        end

        nil
      end

      def validate_message_type(wamp_msg, index, fields, message)
        error = validate_int(wamp_msg[index], index, message)

        return error if error

        fields.message_type = wamp_msg[index]
        nil
      end

      def validate_signature(wamp_msg, index, fields, message)
        error = validate_string(wamp_msg[index], index, message)

        return error if error

        fields.signature = wamp_msg[index]
        nil
      end

      def validate_reason(wamp_msg, index, fields, message)
        error = validate_string(wamp_msg[index], index, message)

        return error if error

        fields.reason = wamp_msg[index]
        nil
      end

      def validate_topic(wamp_msg, index, fields, message)
        error = validate_string(wamp_msg[index], index, message)

        return error if error

        fields.topic = wamp_msg[index]
        nil
      end

      def validate_extra(wamp_msg, index, fields, message)
        error = validate_hash(wamp_msg[index], index, message)

        return error if error

        fields.extra = wamp_msg[index]
        nil
      end

      def validate_options(wamp_msg, index, fields, message)
        error = validate_hash(wamp_msg[index], index, message)

        return error if error

        fields.options = wamp_msg[index]
        nil
      end

      def validate_details(wamp_msg, index, fields, message)
        error = validate_hash(wamp_msg[index], index, message)

        return error if error

        fields.details = wamp_msg[index]
        nil
      end

      def validate_subscription_id(wamp_msg, index, fields, message)
        error = validate_id(wamp_msg[index], index, message)

        return error if error

        fields.subscription_id = wamp_msg[index]
        nil
      end

      def validate_publication_id(wamp_msg, index, fields, message)
        error = validate_id(wamp_msg[index], index, message)

        return error if error

        fields.publication_id = wamp_msg[index]
        nil
      end

      def validate_registration_id(wamp_msg, index, fields, message)
        error = validate_id(wamp_msg[index], index, message)

        return error if error

        fields.registration_id = wamp_msg[index]
        nil
      end

      def validate_hello_details(wamp_msg, index, fields, message) # rubocop: disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
        errors = []
        error = validate_hash(wamp_msg[index], index, message)

        return error if error

        error = validate_authid(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_authrole(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_authmethods(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_roles(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_authextra(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        return errors unless errors.empty?

        fields.details = wamp_msg[index]
        nil
      end

      def validate_welcome_details(wamp_msg, index, fields, message) # rubocop: disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        errors = []
        error = validate_hash(wamp_msg[index], index, message)

        return error if error

        error = validate_roles(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_authid(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_authrole(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_welcome_authmethod(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_roles(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        error = validate_authextra(wamp_msg[index], index, fields, message)
        errors.append(error) if error

        return errors unless errors.empty?

        fields.details = wamp_msg[index]
        nil
      end

      def sanity_check(wamp_message, min_length, max_length, expected_id, message) # rubocop:disable Metrics/MethodLength
        unless wamp_message.is_a?(Array)
          raise ArgumentError, "invalid message type #{wamp_message.class} for #{message}, type should be a list"
        end

        if wamp_message.length < min_length
          raise ArgumentError, "invalid message length #{wamp_message.length}, must be at least #{min_length}"
        end

        if wamp_message.length > max_length
          raise ArgumentError, "invalid message length #{wamp_message.length}, must be at most #{min_length}"
        end

        message_id = wamp_message[0]
        return if message_id == expected_id

        raise ArgumentError, "invalid message id #{message_id} for #{message}, expected #{expected_id}"
      end

      def validate_message(wamp_msg, type, val_spec)
        sanity_check(wamp_msg, val_spec.min_length, val_spec.max_length, type, val_spec.message)
        errors = []
        fields = Fields.new
        val_spec.spec.each do |idx, func|
          error = func.call(wamp_msg, idx, fields, val_spec.message)
          errors.append(error) if error
        end
        raise ArgumentError, errors.join(", ") unless errors.empty?

        fields
      end
    end
  end
end
