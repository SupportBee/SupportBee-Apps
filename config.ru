require './config/load'
SupportBeeApp::Build.build_js if PLATFORM_ENV == 'development'
run RunApp
