Pod::Spec.new do |spec|
  spec.name         = "RxComposableArchitecture"
  spec.version      = "0.1.1"
  spec.summary      = "A RxSwift fork of The Composable Architecture."

  spec.description  = <<-DESC
  Point-Free’s The Composable Architecture uses Apple's Combine framework as the basis of its Effect type. Unfortunately, Combine is only available on iOS 13 and macOS 10.15 and above. In order to be able to use it with earlier versions of the OSes, this fork has adapted The Composable Architecture to use RxSwift as the basis for the Effect type. Much of this work was also inspired by the wonderful ReactiveSwift port of this project as well.
                   DESC

  spec.homepage     = "https://github.com/98prabowo/RxComposableArchitecture"
  spec.authors      = { "98prabowo" => "dimasprabowo98@icloud.com" }
  spec.source       = { :git => "https://github.com/98prabowo/RxComposableArchitecture.git", :tag => "#{spec.version}" }
  spec.license      = { :type => "MIT", :file => "LICENSE" }
    
  spec.swift_version = '5.7'
  spec.ios.deployment_target = "11.0"

  spec.source_files  = "Sources/RxComposableArchitecture/**/*.swift"

  spec.dependency 'CasePaths'
  spec.dependency 'Overture'
  spec.dependency 'RxSwift', '~> 6.5'
  spec.dependency 'RxRelay'
  spec.xcconfig = { 'ENABLE_BITCODE' => 'NO' }
end
