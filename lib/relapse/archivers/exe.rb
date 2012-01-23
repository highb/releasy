require "relapse/archivers/archiver"

module Relapse
  module Archivers
    class Exe < Archiver
      TYPE = :exe
      DEFAULT_EXTENSION = ".exe"

      SFX_NAME = "7z.sfx"
      SFX_FILE = File.expand_path("../../../../bin/#{SFX_NAME}", __FILE__)

      Archivers.register self

      protected
      def command(folder)
        %[7z a -mmt -bd -t7z -sfx#{SFX_NAME} "#{package(folder)}" "#{folder}"]
      end
    end
  end
end