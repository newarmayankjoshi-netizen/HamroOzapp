#!/usr/bin/env bash
set -euo pipefail

echo "Applying macOS linker-warnings fixes..."

cat > macos/Podfile <<'RUBY'
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure \"flutter pub get\" is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Flutter-Generated.xcconfig, then run \"flutter pub get\""
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_macos_podfile_setup

target 'Runner' do
  use_frameworks!

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  suppress_warnings_for = %w[
    FirebaseAuth
    FirebaseStorage
    FirebaseCrashlytics
    sign_in_with_apple
    gRPC-Core
  ]

  installer.pods_project.targets.each do |target|
    # Some pods still declare 10.11/10.12 which is no longer supported by
    # recent Xcode toolchains. Force everything to a supported minimum.
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'

      if suppress_warnings_for.include?(target.name)
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'

        existing = config.build_settings['OTHER_SWIFT_FLAGS']
        existing_flags = case existing
                         when Array
                           existing
                         when String
                           existing.split(' ')
                         else
                           []
                         end
        existing_flags << '$(inherited)' if existing_flags.empty?
        existing_flags << '-suppress-warnings' unless existing_flags.include?('-suppress-warnings')
        config.build_settings['OTHER_SWIFT_FLAGS'] = existing_flags.join(' ')
      end
    end
    # Ensure plugin targets don't add duplicate explicit -lc++ flags which
    # cause "ignoring duplicate libraries: '-lc++'" linker warnings.
    target.build_configurations.each do |config|
      existing_ldflags = config.build_settings['OTHER_LDFLAGS']
      if existing_ldflags
        flags = case existing_ldflags
                when Array
                  existing_ldflags
                when String
                  existing_ldflags.split(' ')
                else
                  []
                end
        # remove any explicit -lc++ occurrences
        flags = flags.reject { |f| f.strip == '-lc++' }
        config.build_settings['OTHER_LDFLAGS'] = flags.join(' ') unless flags.empty?
      end
    end
    flutter_additional_macos_build_settings(target)
  end
end
RUBY

cat > macos/Runner/Configs/Debug.xcconfig <<'XC'
#include? "../../Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "AppInfo.xcconfig"
#include "../../Flutter/Flutter-Debug.xcconfig"
#include "Warnings.xcconfig"

XC

cat > macos/Runner/Configs/Release.xcconfig <<'XC'
#include? "../../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "AppInfo.xcconfig"
#include "../../Flutter/Flutter-Release.xcconfig"
#include "Warnings.xcconfig"

XC

cat > macos/Runner/Configs/Profile.xcconfig <<'XC'
#include? "../../Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#include "AppInfo.xcconfig"
#include "../../Flutter/Flutter-Release.xcconfig"
#include "Warnings.xcconfig"

XC

chmod 0644 macos/Podfile macos/Runner/Configs/Debug.xcconfig macos/Runner/Configs/Release.xcconfig macos/Runner/Configs/Profile.xcconfig

echo "Applied macOS fixes. Run 'pod install --project-directory=macos' then rebuild (flutter run -d macos)."
