uname -rs 
ifconfig -a 
ps -axuww | grep named 
grep named /etc/rc.conf 
dig @имя_твоего_name_server'а version.bind chaos txt 
sockstat | grep named
