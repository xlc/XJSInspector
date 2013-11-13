def import_pods
    pod 'XLCUtils', :head
    pod 'ThoMoNetworking', :head
    pod 'XJSBinding', :head
end

def import_pods_test
    pod 'OCMock', '~> 2.2.1', :inhibit_warnings => true
end

target 'XJSInspector' do
    platform :osx, '10.8'
    import_pods

    post_install do |installer|
        default_library = installer.libraries.detect { |i| i.target_definition.name == 'XJSInspector' }
        config_file_path = default_library.library.xcconfig_path

        File.open("config.tmp", "w") do |io|
            io << File.read(config_file_path).gsub(/OTHER_LDFLAGS.*$/, '')
        end

        FileUtils.mv("config.tmp", config_file_path)
    end

    target 'XJSInspectorTests', :exclusive => true do
        import_pods_test
    end
end



