#
#  Be sure to run `pod spec lint Doorbell.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "Doorbell"
  s.version      = "0.2.4"
  s.summary      = "In-app user feedback SDK for Doorbell.io"
  s.description  = "Easily collect in-app feedback from your users, for free!"
  s.homepage     = "https://doorbell.io"
  s.license      = "MIT"
  s.author    = "Doorbell.io Ltd"
  s.social_media_url   = "https://twitter.com/doorbell_io"
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/doorbell/ios-sdk.git", :tag => "0.2.4" }
  s.source_files  = "Classes"
  s.framework  = "QuartzCore"
  s.requires_arc = true

end
