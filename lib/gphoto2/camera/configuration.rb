module GPhoto2
  class Camera
    module Configuration
      # @param [String] model
      # @param [String] port
      def initialize(model, port)
        reset
      end

      # @return [WindowCameraWidget]
      def window
        @window ||= get_config
      end

      # @example
      #   # List camera configuration keys.
      #   camera.config.keys
      #   # => ['autofocusdrive', 'manualfocusdrive', 'controlmode', ...]
      #
      # @return [Hash<String,GPhoto2::CameraWidget>] a flat map of camera
      #   configuration widgets
      # @see #[]
      # @see #[]=
      def config
        @config ||= window.flatten
      end

      # Reloads the camera configuration.
      #
      # All unsaved changes will be lost.
      #
      # @example
      #   camera['iso']
      #   # => 800
      #
      #   camera['iso'] = 200
      #   camera.reload
      #
      #   camera['iso']
      #   # => 800
      #
      # @return [void]
      def reload
        @window.finalize if @window
        reset
        config
      end

      # @example
      #   camera['whitebalance'].to_s
      #   # => "Automatic"
      #
      # @param [#to_s] key
      # @return [GPhoto2::CameraWidget] the widget identified by `key`
      def [](key)
        config[key.to_s]
      end

      # Updates the attribute identified by `key` with the specified `value`.
      #
      # This marks the configuration as "dirty", meaning a call to {#save} is
      # needed to actually update the configuration on the camera.
      #
      # @example
      #   camera['iso'] = 800
      #   camera['f-number'] = 'f/2.8'
      #   camera['shutterspeed2'] = '1/60'
      #
      # @param [#to_s] key
      # @param [Object] value
      # @return [Object]
      def []=(key, value)
        raise ArgumentError, "invalid key: #{key}" unless self[key]
        self[key].value = value
        @dirty = true
        value
      end

      # Updates the configuration on the camera.
      #
      # @example
      #   camera['iso'] = 800
      #   camera.save
      #   # => true
      #   camera.save
      #   # => false (nothing to update)
      #
      # @return [Boolean] whether setting the configuration was attempted
      def save
        return false unless dirty?
        set_config
        @dirty = false
        true
      end

      # Updates the attributes of the camera from the given Hash and saves the
      # configuration.
      #
      # @example
      #   camera['iso'] # => 800
      #   camera['shutterspeed2'] # => "1/30"
      #
      #   camera.update(iso: 400, shutterspeed2: '1/60')
      #
      #   camera['iso'] # => 400
      #   camera['shutterspeed2'] # => "1/60"
      #
      # @param [Hash<String,Object>] attributes
      # @param [Boolean] force_update mark widgets as changed even if the value is the same to force a write to the camera
      # @return [Boolean] whether the configuration saved
      def update(attributes = {}, force_update=false)
        attributes.each do |key, value|
          self[key] = value

          if force_update && self[key]
            rc = gp_widget_set_changed(self[key].ptr, 1)
            GPhoto2.check!(rc)
          end
        end

        save
      end

      # @example
      #   camera.dirty?
      #   # => false
      #
      #   camera['iso'] = 400
      #
      #   camera.dirty?
      #   # => true
      #
      # @return [Boolean] whether attributes have been changed
      def dirty?
        @dirty
      end

      # Added by ryan to fetch a single value
      def get_single_value(key)
        widget_ptr = FFI::MemoryPointer.new(:pointer)
        rc = gp_camera_get_single_config(ptr, key, widget_ptr, context.ptr)
        GPhoto2.check!(rc)
        widget = FFI::GPhoto2::CameraWidget.new(widget_ptr.read_pointer)
        widget = CameraWidget.factory(widget)

        value = widget.value

        if (old_widget = self[key])
          # Free the old widget
          # old_widget.finalize

          # Replace it with the more recent one
          # @config[key] = widget

          gp_camera_set_single_config(ptr, key, widget.ptr, context.ptr)
        end

        value
      end

      private

      def reset
        @window = nil
        @config = nil
        @dirty = false
      end

      def get_config
        widget_ptr = FFI::MemoryPointer.new(:pointer)
        rc = gp_camera_get_config(ptr, widget_ptr, context.ptr)
        GPhoto2.check!(rc)
        widget = FFI::GPhoto2::CameraWidget.new(widget_ptr.read_pointer)
        CameraWidget.factory(widget)
      end

      def set_config
        rc = gp_camera_set_config(ptr, window.ptr, context.ptr)
        GPhoto2.check!(rc)
      end
    end
  end
end
