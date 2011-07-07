namespace :macro do |ns|

  task :deploy do

    # stop mingle
    mingle_folder = File.expand_path(File.join(ENV['MINGLE_LOCATION']))
    system "#{mingle_folder}/MingleServer stop; sleep 10"

    macro_folder = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    macro_name = File.basename(File.expand_path(File.join(File.dirname(__FILE__), '..')))
    mingle_plugins_folder = File.join(ENV['MINGLE_LOCATION'], 'vendor', 'plugins')

    puts "remove macro if it exists"
    FileUtils.rm_rf(File.join(ENV['MINGLE_LOCATION'], 'vendor', 'plugins', macro_name))
    
    puts "copy macro"
    FileUtils.cp_r(macro_folder, mingle_plugins_folder)

    puts "start mingle"
    system "lexport JAVA_HOME=/usr/lib/jvm/java-6-sun;export PATH=$JAVA_HOME/bin:$PATH;unset GEM_HOME GEM_PATH;#{mingle_folder}/MingleServer --mingle.dataDir=~/mingle/data start"

    puts "#{macro_folder} successfully deployed to #{mingle_plugins_folder}. Mingle server has been restarted."

  end

end