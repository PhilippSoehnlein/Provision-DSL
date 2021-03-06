#!/bin/bash
# set -x
version=`cat dist.ini | grep version | sed -e 's/^.*= //'`
module_dir="Provision-DSL-$version"
perl="/usr/bin/perl"
prove="/usr/bin/prove"
cpanm="$perl ~/tmp/cpanm"
cpanm_opts="-L ~/tmp/local -n --mirror http://10.0.2.2:8080 --mirror-only"

# start plack based cpan server
plackup -M Plack::App::File \
        --port 8080 \
        --daemonize \
        -s Starman \
        --pid /tmp/starman \
        -e "Plack::App::File->new(root => '$HOME/minicpan')->to_app"

if [ ! -f $module_dir/Makefile.PL ]; then
    echo "must run dzil build -- be patient"
    dzil build >/dev/null
fi

echo "copying files"
ssh box "mkdir -p ~/tmp/local; mkdir -p ~/tmp/$module_dir"

rsync -vcr \
    /Users/wolfgang/perl5/perlbrew/bin/cpanm \
    "box:~/tmp/" >/dev/null

rsync -vcr \
    $module_dir/Makefile.PL \
    "box:~/tmp/$module_dir/" >/dev/null

rsync -vcr --delete \
    --exclude /Makefile.PL --exclude '/.git*' --exclude local \
    --exclude '/Provision-DSL-*' \
    . \
    "box:~/tmp/$module_dir/" >/dev/null

echo "checking deps on target"
ssh box "cd ~/tmp/$module_dir; $cpanm $cpanm_opts --installdeps -n ."

# forward options of this script to prove call.
ssh box "cd ~/tmp/$module_dir; PERL5LIB=~/tmp/local/lib/perl5 $prove -lr t $*"

kill `cat /tmp/starman`
