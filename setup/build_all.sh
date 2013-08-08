cp ../output/i386-linux/thalia ./
strip --strip-all thalia
mkdir plugins
cp ../output/i386-linux/plugins/irc.so plugins
strip --strip-all plugins/irc.so