#!/bin/sh

while IFS= read -r extension do
  code --install-extension $extension
done < "./extensions.txt"
