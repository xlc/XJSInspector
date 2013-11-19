Pod::Spec.new do |s|
    s.name         = 'XJSInspector'
    s.version      = '0.0.1'
    s.summary      = 'A runtime debugger use javascript binding'
    s.homepage     = 'https://github.com/xlc/XJSInspector'
    s.license      = 'MIT'
    s.author       = { 'Xiliang Chen' => 'xlchen1291@gmail.com' }
    s.source       = { :git => 'https://github.com/xlc/XJSInspector.git', :commit => '90ab5dde017352ba4e0d05d3313e61bb60114083' }
    s.source_files = 'XJSInspector/**/*.{h,hh,m,mm}', 'Shared/**/*'
    s.private_header_files = '*Private.h', '*.hh'

    s.requires_arc = true

    s.dependency 'XLCUtils'
    s.dependency 'XJSBinding'
    s.dependency 'ThoMoNetworking'

    s.ios.deployment_target = '6.0'
    s.osx.deployment_target = '10.8'
end


