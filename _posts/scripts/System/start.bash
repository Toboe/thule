jls | awk '/waterjail/ {print($1)}' | xargs -I {} jexec {} sh /var/subsonic/subsonic.sh > /dev/console
jls | awk '/ngix/ {print($1)}' | xargs -I {} jexec {} python /usr/local/www/klaus/quickstart.py 192.168.1.12 8080 /home/git/repositories/gitosis-admin.git /home/git/repositories/localsite.git /home/git/repositories/test.git /home/sshare/Share/  &

