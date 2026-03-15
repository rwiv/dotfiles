#!/bin/sh

## python
pipx install tldr

## nodejs
npm install -g agent-browser
# agent-browser는 내부적으로 playwright을 사용한다. 만약 다른 프로젝트에서 uv run playwright install을 수행했다면, agent-browser install를 수행할 필요는 없다.

npm install -g @google/gemini-cli
