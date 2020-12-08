## local

```bash
    $ ./build.sh
    $ vagrant up
```

## usage

```bash
vagrant init ysicing/debian
vagrant up
```

默认用户名`root/vagrant`,默认Debian 10.7

## intro

```
~$ uname -a
Linux debian1070-1 4.19.0-13-amd64 #1 SMP Debian 4.19.160-2 (2020-11-28) x86_64 GNU/Linux

~$ ergo version
效能工具: ergo
 Version:           1.0.8
 Go version:        go1.15.6
 Git commit:        97a96f7eaa36ba88f7ad6fd4f251cc7343fd1447
 Built:             2020-12-08 21:57:49
 OS/Arch:           linux/amd64
 Experimental:      false
 Repo: https://github.com/ysicing/ergo/releases/tag/1.0.8

~# ergo vm init --local #  初始化debian
~# ergo vm upcore --local # 升级内核

# 可能存在 bash: update-grup: command not found

export PATH=/usr/sbin:$PATH 
在执行
```