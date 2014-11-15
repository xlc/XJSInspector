source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:xlc/Specs.git'

def import_pods
    pod 'XLCUtils'
    pod 'ThoMoNetworking'
end

def import_pods_test
    pod 'OCMock', '~> 2.2.1', :inhibit_warnings => true
end

target 'XJSInspector' do
    platform :osx, '10.9'
    import_pods
    pod 'XJSBinding'

    target 'XJSInspectorTests', :exclusive => true do
        import_pods_test
    end
end

target 'XJSInspector-ios' do
    platform :ios, '7.0'
    import_pods
    pod 'XJSBinding'

    target 'XJSInspectorTests-ios', :exclusive => true do
        import_pods_test
    end

    target 'XJSInspectorTests-ios-device', :exclusive => true do
        import_pods_test
    end
end

target 'XJSInspectorTerminal' do
    platform :osx, '10.9'

    import_pods
    pod 'XJSBinding'

    target 'XJSInspectorTerminalTests', :exclusive => true do
        import_pods_test
    end
end

#post_install do |installer|
#    default_library = installer.libraries.each do |lib|
#        name = lib.target_definition.name
#        if name.start_with?('XJSInspector') and not name.include?('Tests') and name != 'XJSInspectorTerminal'
#            config_file_path = lib.library.xcconfig_path
#
#            File.open("config.tmp", "w") do |io|
#                io << File.read(config_file_path).gsub(/OTHER_LDFLAGS.*$/, '')
#            end
#
#            FileUtils.mv("config.tmp", config_file_path)
#        end
#    end
#
#end
