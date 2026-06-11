#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'FrameExtractionTool.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'FrameExtractionTool' }
share_target = project.targets.find { |t| t.name == 'ShareExtension' }

puts "📱 Configuring Info.plist keys for URL scheme..."

# Add URL Types to main target's build settings
main_target.build_configurations.each do |config|
  # The URL scheme needs to be in the Info.plist, which is generated
  # We'll add it to the build settings as INFOPLIST_KEY_
  config.build_settings['INFOPLIST_KEY_CFBundleURLTypes'] = [
    {
      'CFBundleTypeRole' => 'Editor',
      'CFBundleURLName' => 'caspernyong.FrameExtractionTool',
      'CFBundleURLSchemes' => ['frameextractor']
    }
  ].to_s
end

puts "✅ URL scheme configured in build settings"

# Since the project uses GENERATE_INFOPLIST_FILE, we need to use INFOPLIST_KEY_ prefixes
main_target.build_configurations.each do |config|
  # Add URL scheme as separate keys
  config.build_settings['INFOPLIST_KEY_CFBundleURLTypes_0_CFBundleTypeRole'] = 'Editor'
  config.build_settings['INFOPLIST_KEY_CFBundleURLTypes_0_CFBundleURLName'] = 'caspernyong.FrameExtractionTool'
  config.build_settings['INFOPLIST_KEY_CFBundleURLTypes_0_CFBundleURLSchemes_0'] = 'frameextractor'
end

puts "✅ URL scheme keys added"

project.save

puts ""
puts "🎉 URL scheme configuration complete!"
puts ""
puts "URL Scheme: frameextractor://"
puts ""
