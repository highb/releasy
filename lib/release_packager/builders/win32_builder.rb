require "release_packager/builder"

module ReleasePackager
  # General functionality for win32 builders.
  # @abstract
  class Win32Builder < Builder
    OCRA_COMMAND = "ocra"

    def self.valid_for_platform?; RUBY_PLATFORM =~ /win32|mingw/; end

    protected
    def ocra_command
      command = %[#{OCRA_COMMAND} "#{project.executable}" #{project.ocra_parameters} ]
      command += %[--icon "#{project.icon}" ] if project.icon
      command += (project.files - [project.executable]).map {|f| %["#{f}"]}.join(" ")
      command
    end

    protected
    def create_link_files(dir)
      project.send(:links).each_pair do |url, title|
        create_link_file url, File.join(dir, title)
      end
    end

    protected
    def create_installer(file, options = {})
      generate_installer_script file, options
      command = %[#{ocra_command} --chdir-first --no-lzma --innosetup "#{temp_installer_script}"]
      puts command if project.verbose?
      system command
    end

    protected
    def create_link_file(url, title)
      File.open("#{title}.url", "w") do |file|
        file.puts <<END
[InternetShortcut]
URL=#{url}
END
      end
    end

    # Generate innosetup script to build installer.
    protected
    def generate_installer_script(output_file, options = {})
      installer_links = options[:links]

      File.open(temp_installer_script, "w") do |file|
        file.write <<END
[Setup]
AppName=#{project.underscored_name}
AppVersion=#{project.version}
DefaultDirName={pf}\\#{project.name.gsub(/[^\w\s]/, '')}
DefaultGroupName=#{project.installer_group ? "#{project.installer_group}\\" : ""}#{project.name}
OutputDir=#{File.dirname output_file}
OutputBaseFilename=#{File.basename(output_file).chomp(File.extname(output_file))}
UninstallDisplayIcon={app}\\#{project.underscored_name}.exe
END

        if installer_links
          file.puts "LicenseFile=#{project.license}" if project.license # User must accept license.
          file.puts "SetupIconFile=#{project.icon}" if project.icon
          file.puts

          file.puts "[Files]"

          file.puts %[Source: "#{project.license}"; DestDir: "{app}"] if project.license
          file.puts %[Source: "#{project.readme}";  DestDir: "{app}"; Flags: isreadme] if project.readme

          dir = File.dirname(output_file).tr("/", "\\")
          project.send(:links).each_value do |title|
            file.puts %[Source: "#{dir}\\#{title}.url"; DestDir: "{app}"]
          end
        end

        file.write <<END

[Run]
Filename: "{app}\\#{project.underscored_name}.exe"; Description: "Launch"; Flags: postinstall nowait skipifsilent unchecked

[Icons]
Name: "{group}\\#{project.name}"; Filename: "{app}\\#{project.underscored_name}.exe"
Name: "{group}\\Uninstall #{project.name}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\\#{project.name}"; Filename: "{app}\\#{project.underscored_name}.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:";
Name: desktopicon\\common; Description: "For all users"; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\\user; Description: "For the current user only"; GroupDescription: "Additional icons:"; Flags: exclusive unchecked
Name: quicklaunchicon; Description: "Create a &Quick Launch icon"; GroupDescription: "Additional icons:"; Flags: unchecked
END
      end
    end
  end
end