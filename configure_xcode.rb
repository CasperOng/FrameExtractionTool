#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'FrameExtractionTool.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'FrameExtractionTool' }

puts "📱 Main target found: #{main_target.name}"

# Create the Share Extension target
share_extension_target = project.new_target(
  :app_extension,
  'ShareExtension',
  :ios,
  '17.0',
  project.products_group,
  :swift
)

puts "✅ Created ShareExtension target"

# Set bundle identifier
share_extension_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'caspernyong.FrameExtractionTool.ShareExtension'
  config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  config.build_settings['INFOPLIST_FILE'] = 'ShareExtension/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'ShareExtension/ShareExtension.entitlements'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['MARKETING_VERSION'] = '1.2'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['DEVELOPMENT_TEAM'] = 'H55UV85BMR'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['ENABLE_PREVIEWS'] = 'YES'
end

puts "✅ Configured build settings"

# Find or create ShareExtension group
share_group = project.main_group.groups.find { |g| g.display_name == 'ShareExtension' }
if share_group.nil?
  share_group = project.main_group.new_group('ShareExtension', 'ShareExtension')
end

# Add ShareExtension files
share_view_controller = share_group.new_reference('ShareExtension/ShareViewController.swift')
share_info_plist = share_group.new_reference('ShareExtension/Info.plist')
share_entitlements = share_group.new_reference('ShareExtension/ShareExtension.entitlements')

puts "✅ Added ShareExtension files to project"

# Add ShareViewController to compile sources
share_extension_target.source_build_phase.add_file_reference(share_view_controller)

puts "✅ Added ShareViewController to compile sources"

# Find or create Shared group
shared_group = project.main_group.groups.find { |g| g.display_name == 'Shared' }
if shared_group.nil?
  shared_group = project.main_group.new_group('Shared', 'Shared')
end

shared_manager = shared_group.new_reference('Shared/SharedDataManager.swift')

# Add SharedDataManager to both targets
main_target.source_build_phase.add_file_reference(shared_manager)
share_extension_target.source_build_phase.add_file_reference(shared_manager)

puts "✅ Added SharedDataManager to both targets"

# Add main app entitlements
main_group = project.main_group.groups.find { |g| g.display_name == 'FrameExtractionTool' }
if main_group
  entitlements_ref = main_group.new_reference('FrameExtractionTool/FrameExtractionTool.entitlements')
end

main_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'FrameExtractionTool/FrameExtractionTool.entitlements'
end

puts "✅ Added main app entitlements"

# Create target dependency (main app depends on extension)
main_target.add_dependency(share_extension_target)

puts "✅ Created target dependency"

# Embed the extension in the main app
embed_phase = main_target.copy_files_build_phases.find { |phase| phase.symbol_dst_subfolder_spec == :plug_ins }
if embed_phase.nil?
  embed_phase = main_target.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
end

embed_file = embed_phase.add_file_reference(share_extension_target.product_reference)
embed_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

puts "✅ Configured embed phase"

# Save the project
project.save

puts ""
puts "🎉 Xcode project configuration complete!"
puts ""
puts "Configured:"
puts "  ✅ ShareExtension target created"
puts "  ✅ Bundle ID: caspernyong.FrameExtractionTool.ShareExtension"
puts "  ✅ Build settings configured"
puts "  ✅ ShareViewController added to target"
puts "  ✅ SharedDataManager added to both targets"
puts "  ✅ Entitlements configured"
puts "  ✅ Target dependency created"
puts "  ✅ Embed phase configured"
puts ""
puts "Next: Configuring URL scheme..."
puts ""
