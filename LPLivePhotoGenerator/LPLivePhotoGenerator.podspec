Pod::Spec.new do |s|

  s.name         = "LPLivePhotoGenerator"
  s.version      = "0.1"
  s.summary      = "A swift library for creating and saving Live Photos."
  s.description  = "Convert an image and video into a Live Photo and save it.
  The option to move the paired files with the necessary metadata to another
  path is also provided."
  s.homepage     = "https://github.com/OlegAba/LivePhotoGenerator"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Oleg Abalonski" => "o_abalonski@yahoo.com" }
  s.social_media_url   = "https://github.com/OlegAba"
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/OlegAba/LivePhotoGenerator.git", :tag => "0.1" }
  s.source_files  = "LPLivePhotoGenerator/*swift"

end
