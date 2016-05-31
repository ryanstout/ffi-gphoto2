module FFI
  module LibPtp2
    extend FFI::Library

    ffi_lib 'libptp2'

    attach_function :ptp_nikon_get_liveview_image, [:pointer, :pointer, :pointer], :int
  end
end
