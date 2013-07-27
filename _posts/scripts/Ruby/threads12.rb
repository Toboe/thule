newone = Thread.new {}

newone1 = Thread.new {print newone1.inspect  ; sleep 3; 10.times {|i| i*i }; print newone1.inspect; print "\n" }

#print newone1.inspect
#print "\n"






x = Thread.new {  sleep 2; print "I:Поток_I \n"; print "I:Статический метод без параметров \n"; print "I:Завершен \n" }
a = Thread.new { print "\nII:Поток_II  \n"; print "II:Thread.new - создает новый поток  \n"; sleep 4; print "II:Завершен (После первого) \n" }
   x.join # Let the threads finish before
   a.join # main thread exits...
print "\n"
print newone1.inspect
print "\n"


memory_usage = `ps -o rss= -p #{Process.pid}`.to_i


#   Thread.new { sleep(200) }
#   Thread.new { 1000000.times {|i| i*i } }
#   Thread.new { Thread.stop }
#   Thread.list.each {|t| p t}


#Thread.abort_on_exception = true
 #  t1 = Thread.new do
  #   puts  "In new thread"
   #  raise "Exception from thread"
   #end
   #sleep(1)
   #puts "not reached"