# CloudStack Install script

**���ݤʤΤ�Installer���ޤ���**

## Prepare

* CloudStack��Dir����Master��Agent ���줾���/root/ľ�����֤��ޤ�
* root�Ǽ¹Ԥ��ޤ�

### SSH Auth

1. SSH������ǧ�ڤ�ܤ��Ƥ�������
2. master => agent1, agent2�ǥΥ�ѥ��ˤ�ssh�����󤬽����褦�ˤ��뤳��

## Install

1. Agent����Installer��¹Ԥ��ޤ���(CStack-Agent��Dir)
```bash
  $ cd /root/CStack-installer/CStack-Agent
  $ bash agent-xen-installer.sh
```
2. Agent��Installer������ä���Ƶ�ư����Τ�Checker Script��󤷤ޤ�
3. �ä˰۾郎�ʤ����Ȥ��ǧ�����顢Master�κ�Ȥ˰ܤ�ޤ�
4. Master�� CStack-Master��Dir�˰�ư����Installer��󤷤ޤ�
````bash
  $ cd /root/CStack-installer/CStack-Manager
  $ bash clstack-reinstaller.sh
````
5. Installer������ä��顢WebUI�˥����󤹤�褦�˥�å��������Ф�Τǡ�WebUI�Ǻ�Ȥ�³���Ƴ�ǧ���Ƥ�������
6. �ä˰۾郎�ʤ���д�λ�Ǥ�
7. �ȸ��������Ȥ���Ǥ�������ʬ���ܤǤ⥳�ޥ�ɤǤ��ǧ���Ʋ����� (���

