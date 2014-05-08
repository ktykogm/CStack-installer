# CloudStack Install script

**面倒なのでInstaller作りました**

## Prepare

* CloudStackのDirごとMaster、Agent それぞれの/root/直下に置きます
* rootで実行します

### SSH Auth

1. SSH公開鍵認証を施してください
2. master => agent1, agent2でノンパスにてsshログインが出来るようにすること

## Install

1. AgentからInstallerを実行します。(CStack-AgentのDir)
```bash
  $ cd /root/CStack-installer/CStack-Agent
  $ bash agent-xen-installer.sh
```
2. AgentでInstallerが終わったら再起動するのでChecker Scriptを回します
3. 特に異常がないことを確認したら、Masterの作業に移ります
4. Masterで CStack-MasterのDirに移動し、Installerを回します
````bash
  $ cd /root/CStack-installer/CStack-Manager
  $ bash clstack-reinstaller.sh
````
5. Installerが終わったら、WebUIにログインするようにメッセージが出るので、WebUIで作業を続けて確認してください
6. 特に異常がなければ完了です
7. と言いたいところですが、自分の目でもコマンドでも確認して下さい (一応

