Pod::Spec.new do |spec|
	spec.name					= 'TSRestkitManager'
	spec.version				= '0.1.4'
	spec.license				= { :type => 'Apache' }
	spec.homepage				= 'https://github.com/TacchiStudios/TSRestkitManager'
	spec.authors				= { 'Mark McFarlane' => 'mark@tacchistudios.com' }
	spec.summary				= 'A simple wrapper for setting up RestKit and MagicalRecord.'
	spec.source					= { :git => 'https://github.com/TacchiStudios/TSRestkitManager.git', :tag => "v#{spec.version}" }
	spec.source_files			= 'Pod/*'
	spec.requires_arc			= true
	spec.ios.deployment_target	= '7.0'

	spec.dependency				'RestKit', '~> 0.24.0'
	spec.dependency				'MagicalRecord', '~> 2.2'

	spec.prefix_header_contents = <<-EOS
		#import <SystemConfiguration/SystemConfiguration.h>
		#import <CoreData/CoreData.h>
	EOS
end