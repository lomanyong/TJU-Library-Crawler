TJU Library Crawler
===========
## Overview
元旦期间撸的一个爬虫玩具，主要作用是爬取天津大学图书馆的各类书目信息

天大图书馆的访问实在是慢到无法直视...微北洋的 API 的响应速度因此被拖累了，做爬虫的目的也是为了对图书信息做本地存储，之后 API 调用的时候减少对图书馆的访问，加快 API 响应速度

项目基于 NodeJS，也是我自己第一次用 NodeJS 做的实际的小项目了。

存储模块暂时还没有完成，准备使用 mongodb 。

## Start
如果没有安装 coffeescript，需要先 `sudo npm install -g coffee` 

    npm install
    coffee app.coffee

## TODO
- 存储模块【mongodb】