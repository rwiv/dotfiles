#!/bin/sh

## nodejs
npm install -g @google/gemini-cli

npm install -g agent-browser
agent-browser install

## python
pipx install tldr

pip3 install markdownify
pip3 install playwright
python3 -m playwright install
