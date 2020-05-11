module Fancybox2
  module Utils
    module Os
      extend self

      def identifier
        return @indentifier if @indentifier

        host_os = RbConfig::CONFIG['host_os']
        case host_os
        when /aix(.+)$/
          'aix'
        when /darwin(.+)$/
          'darwin'
        when /linux/
          'linux'
        when /freebsd(.+)$/
          'freebsd'
        when /openbsd(.+)$/
          'openbsd'
        when /netbsd(.*)$/
          'netbsd'
        when /dragonfly(.*)$/
          'dragonflybsd'
        when /solaris2/
          'solaris2'
        when /mswin|mingw32|windows/
          # No Windows platform exists that was not based on the Windows_NT kernel,
          # so 'windows' refers to all platforms built upon the Windows_NT kernel and
          # have access to win32 or win64 subsystems.
          'windows'
        else
          host_os
        end
      end
    end
  end
end
