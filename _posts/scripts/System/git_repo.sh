Creating the Git repositories
Now, let's create some Git repositories. We will create one public and one private repository, which will be located respectively under the /home/git/public and /home/git/private directories.
# mkdir -p /home/git/private/private-repo.git
# mkdir -p /home/git/public/public-repo.git
# cd /home/git/private/private-repo.git && git init --bare --shared
Initialized empty shared Git repository in /usr/home/git/private/private-repo.git/
# cd /home/git/public/public-repo.git && git init --bare --shared
Initialized empty shared Git repository in /usr/home/git/public/public-repo.git/
Let's edit the description files from the private-repo.git and public-repo.git directories and set a nice description of the repositories. Now edit the config files from the same directories and add these lines at the end of the files. Here's an example for the public repo, do the same for the private as well.

[gitweb]
        owner = <Your Name>
        url = git://git.example.com/public/public-repo.git
Now, let's export these repos and set proper permissions, so we can clone and fetch from them:

# touch /home/git/private/private-repo.git/git-daemon-export-ok
# touch /home/git/public/public-repo.git/git-daemon-export-ok
# chown -R git:git /home/git
Starting git-daemon
In order the clients to be able to pull and fetch from the repos we will use the git-daemon(1). Add these lines at the end of your rc.conf file, so that git-daemon is started during boot-time:

# Enable git-daemon
git_daemon_enable="YES"
git_daemon_directory="/usr/home/git"
git_daemon_flags="--syslog --base-path=/usr/home/git --detach --reuseaddr"
Now during boot-time the git-daemon will be started as well. To start git-daemon, without rebooting, execute the following command:

# /usr/local/etc/rc.d/git_daemon start
Pushing content to the repositories
Suppose you are a commiter and want to add some files to the already existing and still empty repositories. You will then create a local directory, git-init(1) it, add the files to the index, commit and push them to the remote repo. Note, that this operations requires that your public SSH key is already present in the authorized_keys file on the remote server:

$ mkdir ~/my-git-repo
$ cd ~/my-git-repo && git init 
Initialized empty Git repository in /home/user/my-git-repo/
$ git remote add origin git@git.example.org:/home/git/public/public-repo.git
$ echo foo > bar
$ git add .
$ git commit
$ git push origin master
Cloning the repositories
Now that you want to clone and track the remote repository what you do is this:

$ git clone git://git.example.org/public/public-repo.git
Using Gitweb
Now that we have some sample content in our repositories, you can navigate through them using your web browser.

Just go to http://git-pub.example.org/ and https://git-priv.example.org/ and you should be able to browse the contents of your private and public repositories.


