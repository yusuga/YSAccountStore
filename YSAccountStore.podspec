Pod::Spec.new do |s|
  s.name = 'YSAccountStore'
  s.version = '0.2.0'
  s.summary = 'Helper of ACAccount.'
  s.homepage = 'https://github.com/yusuga/YSAccountStore'
  s.license = 'MIT'
  s.author = 'Yu Sugawara'
  s.source = { :git => 'https://github.com/yusuga/YSAccountStore.git', :tag => s.version.to_s }
  s.platform = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true
  s.source_files = 'Classes/YSAccountStore/*.{h,m}'
  s.compiler_flags = '-fmodules'
end