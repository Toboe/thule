array=[1,2,33,4,666,5];
puts array;
elements=2;
len = array.length;
    mid = (len/elements)
    chunks = []
    start = 0
    tmp =[]
    1.upto(elements) do |i|
        last = start+mid
           #puts "Last =", last
           #puts "Start =", start
           #puts "Mid =", mid
        last = last-1 unless len%elements >= i
        chunks << array[start..last] || []
        tmp <<  array[start..last]
        start = last+1
    end
   #puts "Chunks", chunks[0]

  class Singleton
    def self.new
        @instance ||= super
      @instance2 
    end
    puts "Singleton"
    @instance
end
 File.open('file.txt', 'w') {|file| # открытие файла «file.txt» для записи («w» - write)
   file.puts 'Wrote some text.'
 }
 #File.open()
 # Actual work
puts "Importing categories [ e[32mDONEe[0m ]"
# Actual work
puts "Importing tags       [e[31mFAILEDe[0m]"
def colorize(text, color_code)
  "#{color_code}#{text}e[0m"
end

def red(text); colorize(text, "e[31m"); end
def green(text); colorize(text, "e[32m"); end

# Actual work
puts 'Importing categories [ ' + green('DONE') + ' ]'
# Actual work
puts 'Importing tags       [' + red('FAILED') + ']'

