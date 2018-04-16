module GPhoto2
  class Error < RuntimeError

    # int port_result => ClassName
    ERROR_MAP = {}

    # Map additional libgphoto2 errors
    FFI::GPhoto2::Result.all.each do |port_result, constant|
      ERROR_MAP[port_result] = self.const_set(constant, Class.new(self)) if port_result < 0 # skip GP_OK
    end



    def self.error_from_port_result(rc)
      ERROR_MAP[rc]&.new(rc) || new(rc)
    end

    def initialize(rc)
      super("#{PortResult.as_string(rc)} (#{rc})")
    end
  end
end
