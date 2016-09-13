Pod::Spec.new do |spec|
	spec.name					= 'TSRestkitManager'
	spec.version				= '0.1.7'
	spec.license				= { :type => 'Apache' }
	spec.homepage				= 'https://github.com/TacchiStudios/TSRestkitManager'
	spec.authors				= { 'Mark McFarlane' => 'mark@tacchistudios.com' }
	spec.summary				= 'A simple wrapper for setting up RestKit and MagicalRecord.'
	spec.source					= { :git => 'https://github.com/TacchiStudios/TSRestkitManager.git', :tag => "v#{spec.version}" }
	spec.source_files			= 'Pod/*'
	spec.requires_arc			= true
	spec.ios.deployment_target	= '7.0'


	spec.default_subspec = 'Core'

	spec.subspec 'Core' do |s|
		s.dependency	'RestKit', '~> 0.27.0'
		s.dependency	'MagicalRecord', '~> 2.3.2'

		s.prefix_header_contents = <<-EOS
			#import <SystemConfiguration/SystemConfiguration.h>
			#import <CoreData/CoreData.h>
		EOS
	end

	spec.subspec 'User' do |s|
		s.source_files	= 'Pod/User/*'
		s.dependency	'UIAlertView-Blocks'
	end
end
