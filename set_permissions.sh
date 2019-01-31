#!/bin/bash
chown -R "$USER:$USER" "$HOME/CS1XA3"
chmod -R 755 "$HOME/CS1XA3/public_html"
chmod -R 770 "$HOME/CS1XA3/private"
chmod 644 README.md

