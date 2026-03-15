#!/bin/sh

## python
pipx install tldr

pip3 install requests
pip3 install beautifulsoup4
pip3 install markdownify

pip3 install playwright
python3 -m playwright install

## nodejs
npm install -g agent-browser
# agent-browser는 내부적으로 playwright를 사용한다. python3 -m playwright install로 이미 브라우저를 설치했기 때문에 agent-browser install를 수행할 필요는 없다.

npm install -g @google/gemini-cli
