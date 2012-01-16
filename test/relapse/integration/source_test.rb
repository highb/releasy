require File.expand_path("../../teststrap", File.dirname(__FILE__))

context "Source in all formats" do
  setup do
    Relapse::Project.new do |p|
      p.name = "Test App"
      p.version = "0.1"
      p.files = source_files
      p.readme = "README.txt"
      p.license = "LICENSE.txt"

      p.add_output :source do |o|
        o.add_archive_format :exe
        o.add_archive_format :zip
        o.add_archive_format :"7z"
      end
      p.add_archive_format :tar_gz
      p.add_archive_format :tar_bz2
    end
  end

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  active_builders_valid

  context "tasks" do
    tasks = [
        [ :Task, "package", %w[package:source] ],
        [ :Task, "package:source", %w[package:source:7z package:source:exe package:source:tar_gz package:source:tar_bz2 package:source:zip] ],
        [ :Task, "package:source:7z", %w[pkg/test_app_0_1_SOURCE.7z] ],
        [ :Task, "package:source:exe", %w[pkg/test_app_0_1_SOURCE.exe] ],
        [ :Task, "package:source:tar_gz", %w[pkg/test_app_0_1_SOURCE.tar.gz] ],
        [ :Task, "package:source:tar_bz2", %w[pkg/test_app_0_1_SOURCE.tar.bz2] ],
        [ :Task, "package:source:zip", %w[pkg/test_app_0_1_SOURCE.zip] ],

        [ :Task, "build", %w[build:source] ],
        [ :Task, "build:source", %w[pkg/test_app_0_1_SOURCE] ],

        [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
        [ :FileCreationTask, "pkg/test_app_0_1_SOURCE", source_files ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.7z", %w[pkg/test_app_0_1_SOURCE] ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.exe", %w[pkg/test_app_0_1_SOURCE] ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.tar.gz", %w[pkg/test_app_0_1_SOURCE] ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.tar.bz2", %w[pkg/test_app_0_1_SOURCE] ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.zip", %w[pkg/test_app_0_1_SOURCE] ],
    ]

    test_tasks tasks
  end

  context "generate folder + exe" do
    hookup {Rake::Task["package:source:exe"].invoke }

    asserts("archive created") { File.size("pkg/test_app_0_1_SOURCE.exe") > 0}
  end

  context "generate folder + tar.gz" do
    hookup {Rake::Task["package:source:tar_gz"].invoke }

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_app_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_app_0_1_SOURCE.tar.gz") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tgzip pkg/test_app_0_1_SOURCE.tar.gz | 7z l -si -bd -ttar` =~ /5 files, 4 folders/m }
  end

  context "generate folder + tar.bz2" do
    hookup {Rake::Task["package:source:tar_bz2"].invoke }

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_app_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_app_0_1_SOURCE.tar.bz2") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tbzip2 pkg/test_app_0_1_SOURCE.tar.bz2 | 7z l -si -bd -ttar` =~ /5 files, 4 folders/m }
  end
end