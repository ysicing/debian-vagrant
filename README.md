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

默认用户名`root/vagrant`,默认Debian 11.0

## intro

```
~$ uname -a
Linux debian1080-1 4.19.0-14-amd64 #1 SMP Debian 4.19.171-2 (2021-01-30) x86_64 GNU/Linux

~$ ergo version
ing config file: /home/vagrant/.config/ergo/config.yaml
效能工具: ergo
 Version:           1.0.13
 Go version:        go1.15.7
 Git commit:        dddc8ff35bc379e14da535a3f13aa1ebf81b0190
 Built:             2021-02-04 16:37:20
 OS/Arch:           linux/amd64
 Experimental:      false
 Repo: https://github.com/ysicing/ergo/releases/tag/1.0.13

~# ergo vm init --local #  初始化debian
~# ergo vm upcore --local # 升级内核

# 可能存在 bash: update-grup: command not found

export PATH=/usr/sbin:$PATH 
在执行
```

### 可能ergo问题

```
curl -s -L https://ghproxy.com/https://github.com/ysicing/ergo/releases/download/1.0.13/ergo_linux_amd64 -o /usr/local/bin/ergo
chmod +x /usr/local/bin/ergo
```