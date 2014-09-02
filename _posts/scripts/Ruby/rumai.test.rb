require '/usr/local/bin/rumai'
colors = %w[ red green blue black orange brown gray navy gold ]
colors.each {|c| system "xterm -bg #{c} -title #{c} -e sh -c read &" }
