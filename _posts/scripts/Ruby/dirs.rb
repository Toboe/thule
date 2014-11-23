class Dir
  def self.require_all(directory)
    self.entries(directory).each do |file|
      if file =~ /\.rb/
        require directory + file
      end
    end
  end
end
#Dir.directory="~/"
#Dir.file="dirs.rb"
print "TROLO"



require 'find'
#Find.find('./') do |f| p f end
#Find.find('../') do |dir| p dir end

#p Dir['**/*.*']


class DirectoryScanner

  def initialize
    @fileAction = nil
    @dirAction = nil
  end

  def on_file(&action)
    @fileAction = action
  end
  
  def on_dir(&action)
    @dirAction = action
  end
  
  def scan_subtree(parentPath)
    Dir.open(parentPath) { |dir|
      for file in dir
        next if file == '.';
        next if file == '..';
        path = parentPath + File::Separator + file
        if File.directory? path
          @dirAction.call(file, path) unless @dirAction.nil?
          scan_subtree(path) 
        else
          @fileAction.call(file, path) unless @fileAction.nil?
        end
      end
    }
  end

end
scanner = DirectoryScanner.new
scanner.on_file { |file, path| puts "  #{file}" }
scanner.on_dir { |file, path| puts "#{path}" }
scanner.scan_subtree('/Users/andreygrabovenko/')
