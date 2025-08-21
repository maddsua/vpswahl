install:
	mkdir -p ~/.local/bin
	cp bin.sh ~/.local/bin/vpswahl
	chmod +x ~/.local/bin/vpswahl
	echo "NOTICE: If the command is still not available, update your .bashrc to include 'export PATH=\$$PATH:~/.local/bin'"

uninstall:
	rm ~/.local/bin/vpswahl
